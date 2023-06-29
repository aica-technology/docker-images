#!/bin/bash

IMAGE_NAME=aica-technology/ros2-control

LOCAL_BASE_IMAGE=false
BASE_IMAGE=ghcr.io/aica-technology/ros2-ws
BASE_TAG=humble
OUTPUT_TAG=""

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
  BUILD_FLAGS+=(--build-arg BASE_IMAGE=aica-technology/ros2-ws)
else
  docker pull "${BASE_IMAGE}:${BASE_TAG}"
fi

BUILD_FLAGS+=(--build-arg BASE_TAG="${BASE_TAG}")
BUILD_FLAGS+=(-t "${IMAGE_NAME}:${OUTPUT_TAG}")

if [[ "${BASE_TAG}" == *"galactic"* ]]; then
  DOCKERFILE=Dockerfile.galactic
elif [[ "${BASE_TAG}" == *"humble"* || "${BASE_TAG}" == *"iron"* ]]; then
  DOCKERFILE=Dockerfile.humble
else
  echo "Invalid base tag. Base tag needs to contain either 'galactic', 'humble' or 'iron'."
  exit 1
fi

DOCKER_BUILDKIT=1 docker build -f "${DOCKERFILE}" "${BUILD_FLAGS[@]}" .
