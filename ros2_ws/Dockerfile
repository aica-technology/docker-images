ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ghcr.io/aica-technology/ros2-ws:v2.0.5-jazzy AS build-go
ARG TARGETPLATFORM
ARG GOVERSION=1.24.2

RUN wget https://go.dev/dl/go${GOVERSION}.linux-${TARGETPLATFORM#*/}.tar.gz -O /tmp/go.tar.gz && \
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz && \
  rm /tmp/go.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin"
WORKDIR /go
COPY config/validate_extension ./
RUN --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/go/pkg/mod \
  go build

FROM ghcr.io/aica-technology/ros2-ws:v2.0.5-jazzy AS final
COPY --chown=${USER}:${USER} ./config/InstallAicaDescriptions.cmake /tmp
RUN sudo mv /tmp/InstallAicaDescriptions.cmake /usr/share/cmake-$(cmake --version | awk '/cmake version/ {split($3, v, "."); print v[1]"."v[2]}')/Modules
RUN sudo rm /usr/bin/validate_json
COPY --from=build-go /go/validate_extension /usr/bin/

# Metadata
ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=iron
ARG VERSION=v0.0.0
LABEL org.opencontainers.image.title="AICA ROS 2 image"
LABEL org.opencontainers.image.description="AICA base ROS 2 image (includes ros2_control)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"base/ws","base":{"name":"'${BASE_IMAGE}':'${BASE_TAG}'","version":"'${VERSION}'"}}'
LABEL devcontainer.metadata='[{"containerUser": "ros2"}]'