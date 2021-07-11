#!/bin/bash
ROS_DISTRO=noetic
docker pull "ros:${ROS_DISTRO}"

IMAGE_NAME=aica-technology/ros-ws:"${ROS_DISTRO}"

BUILD_FLAGS=()
while getopts 'r' opt; do
  case $opt in
    r) BUILD_FLAGS+=(--no-cache) ;;
    *) echo 'Error in command line parsing' >&2
       exit 1
  esac
done
shift "$(( OPTIND - 1 ))"

BUILD_FLAGS+=(--build-arg ROS_DISTRO="${ROS_DISTRO}")

if [[ "$OSTYPE" != "darwin"* ]]; then
  USER_ID="$(id -u "${USER}")"
  GROUP_ID="$(id -g "${USER}")"
  BUILD_FLAGS+=(--build-arg UID="${USER_ID}")
  BUILD_FLAGS+=(--build-arg GID="${GROUP_ID}")
fi

BUILD_FLAGS+=(-t "${IMAGE_NAME}")

DOCKER_BUILDKIT=1 docker build "${BUILD_FLAGS[@]}" .
