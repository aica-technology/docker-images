ARG CPP_DEPS=/tmp/cpp_deps
ARG PY_DEPS=/tmp/py_deps
ARG PYTHON_VERSION=3.12
ARG UBUNTU_VERSION=24.04

ARG TRT_IMAGE_TAG=24.12-py3
ARG TENSORRT_IMAGE=nvcr.io/nvidia/tensorrt:${TRT_IMAGE_TAG}

# TODO: newer versions have issues with eigen3 / main works, but we need a tag (use tag right after v1.22.1 when available)
ARG ONNX_RUNTIME_VERSION=main 

FROM ubuntu:${UBUNTU_VERSION} AS onnx-source

ARG ONNX_RUNTIME_VERSION
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    git

WORKDIR /tmp/onnxruntime
RUN git clone -b ${ONNX_RUNTIME_VERSION} --recursive https://github.com/microsoft/onnxruntime . \
 # TODO: remove this when we have a tag for v1.22.1+ \
 && git checkout 4a730ca \
 && git submodule update --init --recursive

FROM ubuntu:${UBUNTU_VERSION} AS cpu-cpp-builder

ARG CPP_DEPS
ARG PY_DEPS
ARG ONNX_RUNTIME_VERSION
ARG USE_TENSORRT=OFF
ARG USE_TENSORRT_BUILTIN_PARSER=OFF

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
RUN pip install --no-cache-dir --break-system-packages \
  flatbuffers \
  packaging \
  numpy==1.26.4 

WORKDIR /tmp
# install ONNX runtime library
COPY --from=onnx-source /tmp/onnxruntime/ /tmp/onnxruntime
WORKDIR /tmp/onnxruntime
RUN ./build.sh \
  --config Release \
  --build_shared_lib \
  --build_wheel \
  --parallel \
  --skip_tests \
  --compile_no_warning_as_error \
  --skip_submodule_sync \
  --enable_pybind \
  --allow_running_as_root
RUN cmake --install build/Linux/Release --prefix ${CPP_DEPS}
# build python package too
RUN mkdir -p ${PY_DEPS} \ 
  && cd build/Linux/Release/dist/ \
  && pip install --no-cache-dir \
      --target=${PY_DEPS} \
      --no-deps \
      onnxruntime*.whl

FROM ${TENSORRT_IMAGE} AS cuda-cpp-builder
ARG CPP_DEPS ONNX_RUNTIME_VERSION

ARG CPP_DEPS
ARG PY_DEPS
ARG ONNX_RUNTIME_VERSION
ARG USE_CUDA=ON
ARG USE_TENSORRT=ON
ARG USE_TENSORRT_BUILTIN_PARSER=OFF
ARG CMAKE_VERSION=3.28
ARG CMAKE_BUILD=2

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
    tar \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates \
  && mkdir -p ${CPP_DEPS}/lib ${CPP_DEPS}/include

# we need newer cmake for onnxruntime (at least 3.28)
RUN wget -O /tmp/cmake.tar.gz \
      https://cmake.org/files/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.${CMAKE_BUILD}.tar.gz \
 && mkdir -p /opt/cmake \
 && tar --strip-components=1 -C /opt/cmake -xzf /tmp/cmake.tar.gz

WORKDIR /opt/cmake
RUN ./bootstrap \
  && make -j$(nproc) \
  && make install

RUN pip install --no-cache-dir --break-system-packages \
  flatbuffers \
  packaging \
  numpy==1.26.4 

WORKDIR /tmp
# install ONNX runtime library
COPY --from=onnx-source /tmp/onnxruntime/ /tmp/onnxruntime
WORKDIR /tmp/onnxruntime
RUN ./build.sh \
  --config Release \
  --build_shared_lib \
  --build_wheel \
  --parallel \
  --skip_tests \
  --compile_no_warning_as_error \
  --skip_submodule_sync \
  --use_cuda \
  --use_tensorrt \
  --enable_pybind \
  --cuda_home=/usr/local/cuda \
  --cudnn_home=/usr/local/cuda \
  --tensorrt_home=/usr \
  --allow_running_as_root
RUN cmake --install build/Linux/Release --prefix ${CPP_DEPS}
# build python package too
RUN mkdir -p ${PY_DEPS} \ 
  && cd build/Linux/Release/dist/ \
  && pip install --no-cache-dir \
      --target=${PY_DEPS} \
      --no-deps \
      onnxruntime*.whl

FROM python:${PYTHON_VERSION}-slim AS python-builder

ARG TORCH_VARIANT=cpu
ARG TORCH_VERSION=2.6.0
ARG TORCHVISION_VERSION=0.21.0
ARG TORCHAUDIO_VERSION=2.6.0
ARG CU_VERSION=cu126
ARG PY_DEPS
ENV PY_DEPS=${PY_DEPS}

RUN pip install --upgrade pip \
 && mkdir -p ${PY_DEPS}

RUN pip install --no-cache-dir \
      --target=${PY_DEPS} \
      numpy==1.26.4 \
      scipy==1.11.3 \
      supervision==0.25.1 \ 
      h5py==3.14.0 \
      coloredlogs \
      flatbuffers \
      protobuf

RUN if [ "${TORCH_VARIANT}" = "cpu" ]; then \
      INDEX_URL="https://download.pytorch.org/whl/cpu"; \
    else \
      INDEX_URL="https://download.pytorch.org/whl/${CU_VERSION}"; \
    fi \
    && pip install --no-cache-dir \
      --target=${PY_DEPS} \
      --extra-index-url ${INDEX_URL} \
      torch==${TORCH_VERSION} \
      torchvision==${TORCHVISION_VERSION} \
      torchaudio==${TORCHAUDIO_VERSION}

FROM scratch AS cpu

ARG PYTHON_VERSION
ARG CPP_DEPS
ARG PY_DEPS

COPY --from=cpu-cpp-builder ${CPP_DEPS}/lib/ /usr/lib/
COPY --from=cpu-cpp-builder ${CPP_DEPS}/include/ /usr/include/
COPY --from=cpu-cpp-builder ${PY_DEPS} /usr/lib/python${PYTHON_VERSION}/dist-packages/
COPY --from=python-builder ${PY_DEPS} /usr/lib/python${PYTHON_VERSION}/dist-packages/

ARG VERSION=0.0.0
LABEL org.opencontainers.image.title="AICA Machine Learning Toolkit"
LABEL org.opencontainers.image.description="AICA Machine Learning Toolkit (CPU support)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL tech.aica.image.metadata='{"type":"lib"}'

FROM scratch AS gpu

ARG PYTHON_VERSION
ARG CPP_DEPS
ARG PY_DEPS

COPY --from=cuda-cpp-builder ${CPP_DEPS}/lib/ /usr/lib/
COPY --from=cuda-cpp-builder ${CPP_DEPS}/include/ /usr/include/
COPY --from=cuda-cpp-builder ${PY_DEPS} /usr/lib/python${PYTHON_VERSION}/dist-packages/
COPY --from=python-builder ${PY_DEPS} /usr/lib/python${PYTHON_VERSION}/dist-packages/

ARG VERSION=0.0.0
LABEL org.opencontainers.image.title="AICA Machine Learning Toolkit"
LABEL org.opencontainers.image.description="AICA Machine Learning Toolkit (GPU support)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL tech.aica.image.metadata='{"type":"lib"}'