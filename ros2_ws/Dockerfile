ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ghcr.io/aica-technology/ros2-ws:v2.0.6-jazzy AS final

RUN sudo rm -f /etc/apt/sources.list.d/ros*.list || true \
 && sudo mkdir -p /usr/share/keyrings \
 && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    | sudo tee /usr/share/keyrings/ros-archive-keyring.gpg > /dev/null \
 && echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://repo.ros2.org/ubuntu/main noble main" \
    | sudo tee /etc/apt/sources.list.d/ros2-latest.list

RUN sudo apt update \
  && sudo apt upgrade -y --no-install-recommends \
  && sudo apt install -y --no-install-recommends \
       ros-jazzy-rosapi \
  && sudo apt-get clean \
  && sudo rm -rf /var/lib/apt/lists/*


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