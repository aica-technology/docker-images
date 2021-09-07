#!/bin/bash

IMAGE_NAME=aica-technology/cl-ros2-ws

LOCAL_BASE_IMAGE=0
BASE_IMAGE=ghcr.io/aica-technology/ros2-ws
ROS_VERSION=foxy
CL_BRANCH=main

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --local-base)
    LOCAL_BASE_IMAGE=1
    shift 1
    ;;
  --ros-version)
    ROS_VERSION=$2
    shift 2
    ;;
  --cl-branch)
    CL_BRANCH=$2
    shift 2
    ;;
  *)
    echo 'Error in command line parsing' >&2
    exit 1
    ;;
  esac
done

if [ "${LOCAL_BASE_IMAGE}" ]; then
  BASE_IMAGE=aica-technology:ros2-ws
else
  docker pull "${BASE_IMAGE}:${ROS_VERSION}"
fi

BUILD_FLAGS+=(--build-arg ROS_VERSION="${ROS_VERSION}")
BUILD_FLAGS+=(--build-arg CL_BRANCH="${CL_BRANCH}")
BUILD_FLAGS+=(-t "${IMAGE_NAME}:${ROS_VERSION}")

DOCKER_BUILDKIT=1 docker build "${BUILD_FLAGS[@]}" .
