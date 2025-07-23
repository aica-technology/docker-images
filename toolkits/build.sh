#!/bin/bash

TENSORRT_IMAGE=nvcr.io/nvidia/tensorrt
TRT_IMAGE_TAG=24.12-py3
TORCH_VARIANT=cpu
# todo: for consistency, the pytorch version should default to Python 3.12 wheels when we generate them
JETSON_TORCH_VERSION="https://developer.download.nvidia.com/compute/redist/jp/v60dp/pytorch/torch-2.2.0a0+6a974be.nv23.11-cp310-cp310-linux_aarch64.whl"
PYTHON_VERSION=3.12
UBUNTU_VERSION=24.04
TARGET=cpu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

CUDA_TOOLKIT=0
ML_TOOLKIT=0

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --cuda-toolkit)
    CUDA_TOOLKIT=1
    shift 1
    ;;
  --ml-toolkit)
    ML_TOOLKIT=1
    shift 1
    ;;
  --tensorrt-image)
    TENSORRT_IMAGE=$2
    shift 2
    ;;
  --tensorrt-image-tag)
    TRT_IMAGE_TAG=$2
    shift 2
    ;;
  --python-version)
    PYTHON_VERSION=$2
    shift 2
    ;;
  --ubuntu-version)
    UBUNTU_VERSION=$2
    shift 2
    ;;
  --torch-variant)
    if [[ "$2" == "cpu" || "$2" == "gpu" || "$2" == "jetson" ]]; then
      TORCH_VARIANT=$2
      shift 2
    else
      echo "Invalid torch variant specified. Use 'cpu' or 'gpu'."
      exit 1
    fi
    ;;
  --jetson-torch-version)
    JETSON_TORCH_VERSION=$2
    shift 2
    ;;
  --target)
    if [[ "$2" == "cpu" || "$2" == "gpu" ]]; then
      TARGET=$2
    else
      echo "Invalid target specified. Use 'cpu' or 'gpu'."
      exit 1
    fi
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

if [ $CUDA_TOOLKIT -eq 0 ] && [ $ML_TOOLKIT -eq 0 ]; then
  echo "No toolkit selected to build, nothing to do."
elif [ $CUDA_TOOLKIT -eq 1 ] && [ $ML_TOOLKIT -eq 1 ]; then
  echo "CUDA and ML toolkits can not be built simultaneously. Please choose one."
  exit 1
elif [ $CUDA_TOOLKIT -eq 1 ]; then
  VERSION=$(cat "${SCRIPT_DIR}"/VERSION.cuda)-${TRT_IMAGE_TAG}
  IMAGE_NAME="ghcr.io/aica-technology/cuda-toolkit"
  TYPE="cuda"
elif [ $ML_TOOLKIT -eq 1 ]; then
  POSTFIX=${TARGET}-${TRT_IMAGE_TAG}
  if [ $TORCH_VARIANT != $TARGET ]; then
    POSTFIX=${POSTFIX}-${TORCH_VARIANT}
  fi
  if [ $TORCH_VARIANT = "jetson" ]; then
    BUILD_FLAGS+=(--build-arg=TORCH_VERSION=$JETSON_TORCH_VERSION)
  fi
  VERSION=$(cat "${SCRIPT_DIR}"/VERSION.ml)-"${POSTFIX}"
  IMAGE_NAME="ghcr.io/aica-technology/ml-toolkit"
  TYPE="ml"

  BUILD_FLAGS+=(--build-arg=UBUNTU_VERSION=${UBUNTU_VERSION})
  BUILD_FLAGS+=(--build-arg=PYTHON_VERSION=${PYTHON_VERSION})
  BUILD_FLAGS+=(--build-arg=TORCH_VARIANT=${TORCH_VARIANT})
  BUILD_FLAGS+=(--target ${TARGET})
fi

BUILD_FLAGS+=(--build-arg=TENSORRT_IMAGE=${TENSORRT_IMAGE})
BUILD_FLAGS+=(--build-arg=TRT_IMAGE_TAG=${TRT_IMAGE_TAG})
BUILD_FLAGS+=(--build-arg=VERSION=${VERSION})
docker buildx build -f Dockerfile."${TYPE}" -t "${IMAGE_NAME}":v"${VERSION}" "${BUILD_FLAGS[@]}" .
