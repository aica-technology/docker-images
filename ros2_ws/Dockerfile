ARG BASE_TAG=iron
FROM ghcr.io/aica-technology/ros2-control:${BASE_TAG}

ARG VERSION=v0.0.0
ARG BASE_TAG=iron
LABEL org.opencontainers.image.title="AICA ROS 2 image"
LABEL org.opencontainers.image.description="AICA base ROS 2 image (includes ros2_control)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="docker.io/library/ros:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"base/ws","base":{"name":"docker.io/library/ros","version":"'${BASE_TAG}'"}}'