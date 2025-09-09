ARG CPP_DEPS=/tmp/cpp_deps
ARG PY_DEPS=/tmp/py_deps
ARG PYTHON_VERSION=3.12
ARG UBUNTU_VERSION=24.04

ARG TRT_IMAGE_TAG=24.12-py3
ARG TENSORRT_IMAGE=nvcr.io/nvidia/tensorrt

ARG CUDA_TOOLKIT_VARIANT

ARG ONNX_RUNTIME_VERSION=v1.22.2

FROM python:${PYTHON_VERSION}-slim AS python-builder

ARG TARGET=cpu
ARG TORCH_VERSION=2.6.0
ARG TORCHVISION_VERSION=0.21.0
ARG TORCHAUDIO_VERSION=2.6.0
ARG TORCH_SOURCE
ARG TORCHVISION_SOURCE
ARG TORCHAUDIO_SOURCE

ARG CU_VERSION=cu126
ARG PY_DEPS
ENV PY_DEPS=${PY_DEPS}

COPY install_dependencies/requirements.txt /tmp/requirements.txt
COPY install_dependencies/pip-constraints.txt /tmp/constraints.txt

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    g++

RUN pip install --upgrade pip \
 && mkdir -p ${PY_DEPS}

RUN if [ "${TARGET}" = "jetson" ]; then \
      wget -O ${TORCH_VERSION} ${TORCH_SOURCE} && \
      wget -O ${TORCHVISION_VERSION} ${TORCHVISION_SOURCE} && \
      wget -O ${TORCHAUDIO_VERSION} ${TORCHAUDIO_SOURCE} && \
      pip install --no-cache-dir \
        --target=${PY_DEPS} \
        -c /tmp/constraints.txt \
        ${TORCH_VERSION} \
        ${TORCHVISION_VERSION} \
        ${TORCHAUDIO_VERSION}; \
    else \
      if [ "${TARGET}" = "cpu" ]; then \
        INDEX_URL="https://download.pytorch.org/whl/cpu"; \
      else \
        INDEX_URL="https://download.pytorch.org/whl/${CU_VERSION}"; \
      fi; \
      pip install --no-cache-dir \
        --target=${PY_DEPS} \
        -c /tmp/constraints.txt \
        --extra-index-url ${INDEX_URL} \
        torch==${TORCH_VERSION} \
        torchaudio==${TORCHAUDIO_VERSION} \
        torchvision==${TORCHVISION_VERSION}; \
    fi

RUN export PYTHONPATH=${PY_DEPS}:$PYTHONPATH && \
    echo "\ntorch==$(pip show torch | awk '/^Version:/ {print $2}')" >> /tmp/constraints.txt

RUN pip install --no-cache-dir \
      --target=${PY_DEPS} \
      -c /tmp/constraints.txt \
      -r /tmp/requirements.txt

FROM ubuntu:${UBUNTU_VERSION} AS apt-fetch

COPY install_dependencies/apt-packages.txt /tmp/apt-packages.txt
RUN TARGET_APT_PKGS=$(cat /tmp/apt-packages.txt) && \
    set -eux \
    && apt-get update \
    && mkdir -p /tmp/debs /opt/apt_root \
    && cd /tmp/debs \
    && apt-get install --download-only -y ${TARGET_APT_PKGS} \
    && cp /var/cache/apt/archives/*.deb . \
    && for deb in *.deb; do \
         dpkg-deb -x "$deb" /opt/apt_root; \
       done \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /deps
RUN mkdir lib
RUN find /opt/apt_root -type f \( -name "*.so*" -o -name "*.a*" \) -exec cp -L "{}" lib \;
RUN cp -r /opt/apt_root/usr/bin .
RUN cp -r /opt/apt_root/usr/include .

FROM ubuntu:${UBUNTU_VERSION} AS cpp-source

ARG ONNX_RUNTIME_VERSION
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    git

WORKDIR /tmp/onnxruntime
RUN git clone -b ${ONNX_RUNTIME_VERSION} --recursive https://github.com/microsoft/onnxruntime . \
 && git submodule update --init --recursive

FROM ubuntu:${UBUNTU_VERSION} AS cpu-builder

ARG CPP_DEPS
ARG PY_DEPS
ARG ONNX_BUILD_PARALLEL
ARG ONNX_RUNTIME_VERSION

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    git \
    wget \
    python3-pip \
    python3-pybind11 \
    python3-dev \
    libssl-dev \
    libffi-dev \
    flatbuffers-compiler \
    libeigen3-dev \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ${CPP_DEPS}/lib ${CPP_DEPS}/include

RUN PIP_BREAK_SYSTEM_PACKAGES=1 pip install --no-cache-dir \
  flatbuffers==25.2.10 \
  packaging \
  numpy==1.26.4

WORKDIR /tmp
# install ONNX runtime library
COPY --from=cpp-source /tmp/onnxruntime/ /tmp/onnxruntime
WORKDIR /tmp/onnxruntime
RUN set -eux; \
    build_extra="--cmake_extra_defines onnxruntime_BUILD_UNIT_TESTS=OFF"; \
    if [ -n "${ONNX_BUILD_PARALLEL:-}" ]; then \
      build_extra="$build_extra --parallel ${ONNX_BUILD_PARALLEL}"; \
    fi; \
    # no longer available after version 1.22.0
    # ! this does not check for the lower bound version when this argument was introduced
    if [ "$(echo ${ONNX_RUNTIME_VERSION#v} | cut -d. -f1)" -lt 1 ] || \
       { [ "$(echo ${ONNX_RUNTIME_VERSION#v} | cut -d. -f1)" -eq 1 ] && \
         [ "$(echo ${ONNX_RUNTIME_VERSION#v} | cut -d. -f2)" -lt 22 ]; }; then \
      build_extra="$build_extra --use_preinstalled_eigen --eigen_path=/usr/include/eigen3"; \
    fi; \
    ./build.sh \
      --config Release \
      --update --build --build_shared_lib \
      --enable_pybind --build_wheel \
      --skip_tests \
      --allow_running_as_root \
      ${build_extra}
RUN cmake --install build/Linux/Release --prefix ${CPP_DEPS}
# build python package too
RUN mkdir -p ${PY_DEPS} \
  && cd build/Linux/Release/dist/ \
  && pip install --no-cache-dir \
      --target=${PY_DEPS} \
      --no-deps \
      onnxruntime*.whl

FROM ${TENSORRT_IMAGE}:${TRT_IMAGE_TAG} AS cuda-builder

ARG CPP_DEPS
ARG PY_DEPS
ARG USE_CUDA=ON
ARG CMAKE_VERSION=3.31
ARG CMAKE_BUILD=8
ARG PYTHON_VERSION
ARG CUDA_ARCHS=""
ARG ONNX_BUILD_PARALLEL
ARG ONNX_BUILD_FOR_GPU=1
ARG ONNX_RUNTIME_VERSION
ARG TARGET

ENV EXTRA_APT_PKGS=""
RUN if [ "${TARGET}" = "jetson" ]; then \
      EXTRA_APT_PKGS="nvidia-l4t-dla-compiler nvidia-l4t-cudla"; \
    fi

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    git \
    wget \
    python3-pip \
    python3-pybind11 \
    python3-dev \
    libssl-dev \
    libffi-dev \
    flatbuffers-compiler \
    libeigen3-dev \
    libopenblas-dev \
    libopenmpi-dev \
    tar \
    ${EXTRA_APT_PKGS} \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates \
  && mkdir -p ${CPP_DEPS}/lib ${CPP_DEPS}/include

# we need newer cmake for onnxruntime (at least 3.28)
RUN wget -O /tmp/cmake-installer.sh \
    https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}.${CMAKE_BUILD}/cmake-${CMAKE_VERSION}.${CMAKE_BUILD}-linux-`arch`.sh \
  && chmod +x /tmp/cmake-installer.sh && /tmp/cmake-installer.sh --skip-license --prefix=/usr/local

RUN PIP_BREAK_SYSTEM_PACKAGES=1 pip install --no-cache-dir \
  flatbuffers==25.2.10 \
  packaging \
  numpy==1.26.4 \
  psutil==5.9.0

ENV LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/nvidia:${LD_LIBRARY_PATH}

WORKDIR /tmp
# install ONNX runtime library
COPY --from=cpp-source /tmp/onnxruntime/ /tmp/onnxruntime
WORKDIR /tmp/onnxruntime
RUN set -eux; \
    build_extra="--cmake_extra_defines onnxruntime_BUILD_UNIT_TESTS=OFF"; \
    if [ -n "${CUDA_ARCHS:-}" ]; then \
      build_extra="$build_extra --cmake_extra_defines CMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHS}"; \
    fi; \
    if [ -n "${ONNX_BUILD_PARALLEL:-}" ]; then \
      build_extra="$build_extra --parallel ${ONNX_BUILD_PARALLEL}"; \
    fi; \
    # in case we really needs to disable CUDA for onnxruntime, but we still need the remaining dependencies of this stage
    if [ "${ONNX_BUILD_FOR_GPU}" = "1" ]; then \
      build_extra="$build_extra --use_cuda --cuda_home=/usr/local/cuda --cudnn_home=/usr/local/cuda"; \
      build_extra="$build_extra --use_tensorrt --tensorrt_home=/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)"; \
    fi; \
    # no longer available after version 1.22.0
    # ! this does not check for the lower bound version when this argument was introduced
    if [ "$(echo ${ONNX_RUNTIME_VERSION#v} | cut -d. -f1)" -lt 1 ] || \
       { [ "$(echo ${ONNX_RUNTIME_VERSION#v} | cut -d. -f1)" -eq 1 ] && \
         [ "$(echo ${ONNX_RUNTIME_VERSION#v} | cut -d. -f2)" -lt 22 ]; }; then \
      build_extra="$build_extra --use_preinstalled_eigen --eigen_path=/usr/include/eigen3"; \
    fi; \
    ./build.sh \
      --config Release \
      --update --build --build_shared_lib \
      --enable_pybind --build_wheel \
      --skip_tests \
      --allow_running_as_root \
      ${build_extra}
RUN cmake --install build/Linux/Release --prefix ${CPP_DEPS}
# build python package too
RUN mkdir -p ${PY_DEPS} \
  && cd build/Linux/Release/dist/ \
  && pip install --no-cache-dir \
      --target=${PY_DEPS} \
      --no-deps \
      onnxruntime*.whl

COPY --from=python-builder ${PY_DEPS} /usr/lib/python3/dist-packages/
RUN echo "torch==$(pip show torch | awk '/^Version:/ {print $2}') " >> /tmp/constraints.txt && \
    echo "numpy==$(pip show numpy | awk '/^Version:/ {print $2}') " >> /tmp/constraints.txt

COPY install_dependencies/gpu-only-requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir \
      --target=${PY_DEPS} \
      -c /tmp/constraints.txt \
      -r /tmp/requirements.txt

FROM scratch AS cpu

ARG PYTHON_VERSION
ARG CPP_DEPS
ARG PY_DEPS

COPY --from=apt-fetch /deps/lib /usr/lib
COPY --from=apt-fetch /deps/bin /usr/bin
COPY --from=cpu-builder ${CPP_DEPS}/lib/ /usr/lib/
COPY --from=cpu-builder ${CPP_DEPS}/include/ /usr/include/
COPY --from=cpu-builder ${PY_DEPS} /usr/lib/python3/dist-packages/
COPY --from=python-builder ${PY_DEPS} /usr/lib/python3/dist-packages/

ARG VERSION=0.0.0
LABEL org.opencontainers.image.title="AICA Machine Learning Toolkit"
LABEL org.opencontainers.image.description="AICA Machine Learning Toolkit (CPU support)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL tech.aica.image.metadata='{"type":"lib"}'

FROM scratch AS gpu

ARG CUDA_TOOLKIT_VARIANT
ARG PYTHON_VERSION
ARG CPP_DEPS
ARG PY_DEPS

COPY --from=apt-fetch /deps/lib /usr/lib
COPY --from=apt-fetch /deps/bin /usr/bin
COPY --from=cuda-builder ${CPP_DEPS}/lib/ /usr/lib/
COPY --from=cuda-builder ${CPP_DEPS}/include/ /usr/include/
COPY --from=cuda-builder ${PY_DEPS} /usr/lib/python3/dist-packages/
COPY --from=python-builder ${PY_DEPS} /usr/lib/python3/dist-packages/

ARG VERSION=0.0.0
LABEL org.opencontainers.image.title="AICA Machine Learning Toolkit"
LABEL org.opencontainers.image.description="AICA Machine Learning Toolkit (GPU support)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL tech.aica.image.metadata='{"type":"lib","dependencies":{"@aica/foss/toolkits/cuda": ">= v1.0.0-0, < v1.0.0-zzzzz"}}'