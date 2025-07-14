#!/bin/bash

IMAGE_NAME=ghcr.io/aica-technology/ros2-ws
BASE_TAG=jazzy
ROS_DISTRO=jazzy
NVIDIA_BASE_TAG=25.06-py3
WITH_NVIDIA=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [[ ! -f "${SCRIPT_DIR}"/config/sshd_entrypoint.sh ]]; then
  mkdir -p "${SCRIPT_DIR}"/config
  cp "$(dirname "${SCRIPT_DIR}")"/common/sshd_entrypoint.sh "${SCRIPT_DIR}"/config/ || exit 1
fi
if [[ ! -f "${SCRIPT_DIR}"/config/config.rviz ]]; then
  mkdir -p "${SCRIPT_DIR}"/config
  cp "$(dirname "${SCRIPT_DIR}")"/common/config.rviz "${SCRIPT_DIR}"/config/ || exit 1
fi

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --base-tag)
    BASE_TAG=$2
    shift 2
    ;;
  --ros-distro)
    ROS_DISTRO=$2
    shift 2
    ;;
  -r | --rebuild)
    BUILD_FLAGS+=(--no-cache)
    shift 1
    ;;
  -v | --verbose)
    BUILD_FLAGS+=(--progress=plain)
    shift 1
    ;;
  --nvidia)
    WITH_NVIDIA=true
    shift 1
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [[ "${WITH_NVIDIA}" == true ]]; then
  if [[ "${ROS_DISTRO}" == "humble" ]]; then
    NVIDIA_BASE_TAG=24.10-py3
  fi
  VERSION=$(cat "${SCRIPT_DIR}"/VERSION.nvidia)
  BUILD_FLAGS+=(--build-arg=NVIDIA_BASE_TAG=${NVIDIA_BASE_TAG})
  BUILD_FLAGS+=(--build-arg=ROS_DISTRO=${ROS_DISTRO})
  BUILD_FLAGS+=(--build-arg=VERSION=${VERSION}-${ROS_DISTRO}-nvidia)
  docker buildx build -f Dockerfile.nvidia -t "${IMAGE_NAME}":v"${VERSION}"-"${ROS_DISTRO}-nvidia" "${BUILD_FLAGS[@]}" .
else
  VERSION=$(cat "${SCRIPT_DIR}"/VERSION."${ROS_DISTRO}")
  BUILD_FLAGS+=(--build-arg=BASE_TAG=${BASE_TAG})
  BUILD_FLAGS+=(--build-arg=ROS_DISTRO=${ROS_DISTRO})
  BUILD_FLAGS+=(--build-arg=VERSION=${VERSION}-${ROS_DISTRO})
  docker buildx build -t "${IMAGE_NAME}":v"${VERSION}"-"${ROS_DISTRO}" "${BUILD_FLAGS[@]}" .
fi
