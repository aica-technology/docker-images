ARG BASE_TAG=24.04
FROM ubuntu:${BASE_TAG} AS base
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    cmake \
    g++ \
    git
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

ARG CMAKE_BUILD_TYPE=Release

FROM base AS apt-dependencies
COPY apt-packages.tx[t] /

RUN <<HEREDOC
if [ ! -s /apt-packages.txt ]; then
  set +e # FIXME: without this, the script fails because of an issue with `clear_console`
  exit 0
fi

mkdir -p /tmp/apt

apt-get update
# We then do a dry-run and parse the output of apt to gather the list of packages to be installed
# Example output:
# ```
# #########
# NOTE: This is only a simulation!
#       apt-get needs root privileges for real execution.
#       Keep also in mind that locking is deactivated,
#       so don't depend on the relevance to the real current situation!
# Reading package lists...
# Building dependency tree...
# Reading state information...
# The following additional packages will be installed:
#   libavutil56 libblosc1
# The following NEW packages will be installed:
#   libavutil56 libblosc1
# 0 upgraded, 5 newly installed, 0 to remove and 28 not upgraded.
# Inst libavutil56 (7:4.4.2-0ubuntu0.22.04.1 Ubuntu:22.04/jammy-updates, Ubuntu:22.04/jammy-security [arm64])
# Inst libblosc1 (1.21.1+ds2-2 Ubuntu:22.04/jammy [arm64])
# Conf libavutil56 (7:4.4.2-0ubuntu0.22.04.1 Ubuntu:22.04/jammy-updates, Ubuntu:22.04/jammy-security [arm64])
# Conf libblosc1 (1.21.1+ds2-2 Ubuntu:22.04/jammy [arm64])
# ```
# Transformed into:
# ```
# libavutil56
# libblosc1
# ```
xargs -a /apt-packages.txt apt-get install --dry-run \
  | grep -e '^Inst ' \
  | sed -E 's/^Inst (\S+) .*$/\1/' > /tmp/new-packages.txt
# Then we install apt packages like normal
xargs -a /apt-packages.txt apt-get install -y
# Finally we use dpkg to get all files installed by those packages and copy them to a new root
#  - get list of files installed by all the packages
#  - remove empty lines
#  - sort
#  - remove duplicates
#  - copy files while keeping file hierarchy and preserving links as-is
#  - remove "omitting directory" messages (we don't do recursive copy as we only want specific files) for cleaner output
xargs -a /tmp/new-packages.txt dpkg-query -L \
  | sed '/^$/d' | sort | uniq \
  | xargs -d "\n" cp --parents -dp -t /tmp/apt  2>&1 \
  | grep -v 'omitting directory'
# this root can then be copied to / to install everything globally or use LD_LIBRARY_PATH to use it locally
HEREDOC

FROM base AS eigenpy
ARG ARCH
ARG TARGETPLATFORM
ARG CACHEID
ARG EIGENPY_TAG=v3.12.0
COPY --from=apt-dependencies /tmp/apt /
ENV LD_LIBRARY_PATH=/usr/lib/${ARCH}-linux-gnu/openblas-pthread:$LD_LIBRARY_PATH

RUN --mount=type=cache,target=/eigenpy,id=cmake-eigenpy-${EIGENPY_TAG}-${TARGETPLATFORM}-${CACHEID},uid=1000 \
  if [ ! -f /eigenpy/eigenpy/CMakeLists.txt ]; then \
    git clone --depth 1 -b ${EIGENPY_TAG} --recursive https://github.com/stack-of-tasks/eigenpy /eigenpy/eigenpy; \
  fi && \
  cmake -B /eigenpy/build -S /eigenpy/eigenpy -DBUILD_TESTING=OFF -DBUILD_TESTING_SCIPY=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
    -DPYTHON_EXECUTABLE=$(which python3) -DGENERATE_PYTHON_STUBS=ON -DCMAKE_INSTALL_PREFIX=/tmp/deps && \
  cmake --build /eigenpy/build --target all install

FROM base AS pinocchio-dependencies
ARG ARCH
ARG TARGETPLATFORM
ARG CACHEID
ARG OCTOMAP_TAG=v1.10.0
ARG HPP_FCL_TAG=v2.4.5
COPY --from=apt-dependencies /tmp/apt /
COPY --from=eigenpy /tmp/deps /usr
ENV LD_LIBRARY_PATH=/usr/lib/${ARCH}-linux-gnu/openblas-pthread:$LD_LIBRARY_PATH
RUN --mount=type=cache,target=/octomap,id=cmake-octomap-src-${OCTOMAP_TAG}-${TARGETPLATFORM}-${CACHEID},uid=1000 \
  --mount=type=cache,target=/coal,id=cmake-coal-src-${HPP_FCL_TAG}-${TARGETPLATFORM}-${CACHEID},uid=1000 \
  --mount=type=cache,target=/build,id=cmake-${HPP_FCL_TAG}-${OCTOMAP_TAG}-${TARGETPLATFORM}-${CACHEID},uid=1000 \
<<EOF
set -e

if [ ! -f /octomap/CMakeLists.txt ]; then
  rm -rf /octomap/*
  git clone --depth 1 -b ${OCTOMAP_TAG} --recursive https://github.com/OctoMap/octomap /octomap
fi

cmake -B /build/octomap -S octomap -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/tmp/deps
cmake --build /build/octomap --target all install

if [ ! -f /coal/CMakeLists.txt ]; then
  rm -rf /coal/*
  git clone --depth 1 -b ${HPP_FCL_TAG} --recursive https://github.com/coal-library/coal /coal
fi

cmake -B /build/coal -S coal -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DBUILD_PYTHON_INTERFACE=ON \
  -DPYTHON_EXECUTABLE=$(which python3) -DGENERATE_PYTHON_STUBS=ON -DCMAKE_INSTALL_PREFIX=/tmp/deps
cmake --build /build/coal --target all install

EOF

FROM base AS pinocchio
ARG ARCH
ARG TARGETPLATFORM
ARG CACHEID
ARG PINOCCHIO_TAG=v3.9.0
COPY --from=apt-dependencies /tmp/apt /
COPY --from=eigenpy /tmp/deps /usr
COPY --from=pinocchio-dependencies /tmp/deps /usr
ENV LD_LIBRARY_PATH=/usr/lib/${ARCH}-linux-gnu/openblas-pthread:$LD_LIBRARY_PATH
# For Python stubs generation, pinocchio can only import hppfcl from dist-packages
RUN mv /usr/lib/python3.12/site-packages/hppfcl /usr/lib/python3/dist-packages

RUN --mount=type=cache,target=/pinocchio,id=cmake-pinocchio-${PINOCCHIO_TAG}-${TARGETPLATFORM}-${CACHEID},uid=1000 \
  if [ ! -f /pinocchio/pinocchio/CMakeLists.txt ]; then \
    git clone --depth 1 -b ${PINOCCHIO_TAG} --recursive https://github.com/stack-of-tasks/pinocchio /pinocchio/pinocchio; \
  fi && \
  cmake -B /pinocchio/build -S /pinocchio/pinocchio -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DBUILD_EXAMPLES=OFF \
    -DBUILD_WITH_COLLISION_SUPPORT=ON -DBUILD_PYTHON_INTERFACE=ON -DPYTHON_EXECUTABLE=$(which python3) -DGENERATE_PYTHON_STUBS=ON -DCMAKE_INSTALL_PREFIX=/tmp/deps && \
  cmake --build /pinocchio/build --target all install

# FIXME: pinocchio produces non-portable paths
RUN find /tmp/deps -type f -exec sed -i 's#/tmp/deps#/usr#g' '{}' \;

FROM scratch AS production
COPY --from=apt-dependencies /tmp/apt /
COPY --from=eigenpy /tmp/deps /usr
COPY --from=pinocchio-dependencies /tmp/deps /usr
COPY --from=pinocchio /tmp/deps /usr

ARG BASE_TAG=24.04
ARG VERSION
LABEL org.opencontainers.image.title="Pinocchio dependencies image"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="ubuntu:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"lib","base":{"name":"ubuntu:'${BASE_TAG}'","version":"'${VERSION}'"}}'
