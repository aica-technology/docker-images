#!/bin/bash

IMAGE_NAME=ghcr.io/aica-technology/camera_calibration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
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

VERSION=$(cat "${SCRIPT_DIR}"/VERSION)
docker buildx build -t "${IMAGE_NAME}":"${VERSION}" "${BUILD_FLAGS[@]}" .
