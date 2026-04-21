#!/bin/bash

IMAGE_NAME=ghcr.io/aica-technology/pinocchio
BASE_TAG=24.04

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --base-tag)
    BASE_TAG=$2
    shift 2
    ;;
  -r | --rebuild)
    BUILD_FLAGS+=(--no-cache --build-arg=CACHEID=$(date +%s))
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

VERSION=$(cat "${SCRIPT_DIR}"/VERSION)
BUILD_FLAGS+=(--build-arg=ARCH=$(arch))
BUILD_FLAGS+=(--build-arg=BASE_TAG=${BASE_TAG})
BUILD_FLAGS+=(--build-arg=VERSION=${VERSION})
docker buildx build -t "${IMAGE_NAME}":v"${VERSION}" "${BUILD_FLAGS[@]}" .
