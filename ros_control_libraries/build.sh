#!/bin/bash

IMAGE_NAME=aica-technology/ros-control-libraries

LOCAL_BASE_IMAGE=false
BASE_IMAGE=ghcr.io/aica-technology/ros-ws
BASE_TAG=noetic
CL_BRANCH=develop

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --local-base)
    LOCAL_BASE_IMAGE=true
    shift 1
    ;;
  --ros-version)
    BASE_TAG=$2
    shift 2
    ;;
  --cl-branch)
    CL_BRANCH=$2
    shift 2
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [ "${LOCAL_BASE_IMAGE}" == true ]; then
  BUILD_FLAGS+=(--build-arg BASE_IMAGE=aica-technology/ros-ws)
else
  docker pull "${BASE_IMAGE}:${BASE_TAG}"
fi

BUILD_FLAGS+=(--build-arg BASE_TAG="${BASE_TAG}")
BUILD_FLAGS+=(--build-arg CL_BRANCH="${CL_BRANCH}")
BUILD_FLAGS+=(-t "${IMAGE_NAME}:${BASE_TAG}")

DOCKER_BUILDKIT=1 docker build "${BUILD_FLAGS[@]}" .
