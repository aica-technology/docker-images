#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

IMAGE_NAME=ghcr.io/aica-technology/yolo_model_converter
VERSION=$(cat VERSION)
MODEL="yolo12n.pt"


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
  --model)
    MODEL=$2
    shift 2
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

VERSION=$(cat "${SCRIPT_DIR}"/VERSION)
docker buildx build -t "${IMAGE_NAME}":v"${VERSION}" "${BUILD_FLAGS[@]}" .

docker run --rm -it \
    -e UID=$(id -u) \
    -e GID=$(id -g) \
    -e model="${MODEL}" \
    -v .:/exports \
    --name yolo_model_converter \
    ghcr.io/aica-technology/yolo_model_converter:v${VERSION}