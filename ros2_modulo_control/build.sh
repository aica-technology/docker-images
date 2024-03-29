#!/bin/bash

IMAGE_NAME=aica-technology/ros2-modulo-control

LOCAL_BASE_IMAGE=false
BASE_IMAGE=ghcr.io/aica-technology/ros2-control-libraries
BASE_TAG=humble
OUTPUT_TAG=""
MODULO_BRANCH=main

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --local-base)
    LOCAL_BASE_IMAGE=true
    shift 1
    ;;
  --base-tag)
    BASE_TAG=$2
    shift 2
    ;;
  --modulo-branch)
    MODULO_BRANCH=$2
    shift 2
    ;;
  --output-tag)
    OUTPUT_TAG=$2
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
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [ -z "${OUTPUT_TAG}" ]; then
  echo "Output tag is empty, using the base tag as output tag."
  OUTPUT_TAG="${BASE_TAG}"
fi

if [ "${LOCAL_BASE_IMAGE}" = true ]; then
  BUILD_FLAGS+=(--build-arg BASE_IMAGE=aica-technology/ros2-control-libraries)
else
  docker pull "${BASE_IMAGE}:${BASE_TAG}"
fi

BUILD_FLAGS+=(--build-arg BASE_TAG="${BASE_TAG}")
BUILD_FLAGS+=(--build-arg MODULO_BRANCH="${MODULO_BRANCH}")
BUILD_FLAGS+=(-t "${IMAGE_NAME}:${OUTPUT_TAG}")

DOCKER_BUILDKIT=1 docker build "${BUILD_FLAGS[@]}" .
