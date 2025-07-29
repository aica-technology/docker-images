#!/bin/bash

TENSORRT_IMAGE=nvcr.io/nvidia/tensorrt
TRT_IMAGE_TAG=24.12-py3

TORCH_VARIANT=cpu
TORCH_VERSION="2.6.0"
JETSON_TORCH_VERSION="torch-2.3.0-cp310-cp310-linux_aarch64.whl"
JETSON_TORCHVISION_VERSION="torchvision-0.18.0a0+6043bc2-cp310-cp310-linux_aarch64.whl"
JETSON_TORCHAUDIO_VERSION="torchaudio-2.3.0+952ea74-cp310-cp310-linux_aarch64.whl"
JETSON_TORCH_SOURCE="https://nvidia.box.com/shared/static/mp164asf3sceb570wvjsrezk1p4ftj8t.whl"
JETSON_TORCHVISION_SOURCE="https://nvidia.box.com/shared/static/xpr06qe6ql3l6rj22cu3c45tz1wzi36p.whl"
JETSON_TORCHAUDIO_SOURCE="https://nvidia.box.com/shared/static/9agsjfee0my4sxckdpuk9x9gt8agvjje.whl"

PYTHON_VERSION=3.12
UBUNTU_VERSION=24.04
ROS_DISTRO=jazzy

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
  --ros-distro)
    ROS_DISTRO=$2
    shift 2
    ;;

  --torch-variant)
    if [[ "$2" =~ ^(cpu|gpu|jetson)$ ]]; then
      TORCH_VARIANT=$2
      shift 2
    else
      echo "Invalid torch variant specified. Use 'cpu' or 'gpu'."
      exit 1
    fi
    ;;
  --torch-version)
    TORCH_VERSION=$2
    shift 2
    ;;

  --jetson-torch-version)
    JETSON_TORCH_VERSION=$2
    shift 2
    ;;
  --jetson-torch-source)
    JETSON_TORCH_SOURCE=$2
    shift 2
    ;;
  --jetson-torchvision-version)
    JETSON_TORCHVISION_VERSION=$2
    shift 2
    ;;
  --jetson-torchvision-source)
    JETSON_TORCHVISION_SOURCE=$2
    shift 2
    ;;
  --jetson-torchaudio-version)
    JETSON_TORCHAUDIO_VERSION=$2
    shift 2
    ;;
  --jetson-torchaudio-source)
    JETSON_TORCHAUDIO_SOURCE=$2
    shift 2
    ;;

  --target)
    TARGET=$2
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
  --) # we can use this to use more flags that are not named by default
    shift
    break
    ;;

  esac
done

while [ "$#" -gt 0 ]; do
  if [[ "$1" != --* ]]; then
    echo "Expected build-arg in --key value form, got: $1" >&2
    exit 1
  fi

  KEY="${1#--}"
  VAL="$2"
  if [ -z "$VAL" ] || [[ "$VAL" == --* ]]; then
    echo "Missing value for build-arg '$KEY'" >&2
    exit 1
  fi

  ENVKEY="${KEY^^}"
  ENVKEY="${ENVKEY//-/_}"
  BUILD_FLAGS+=( "--build-arg=${ENVKEY}=${VAL}" )
  shift 2
done


if [ $CUDA_TOOLKIT -eq 0 ] && [ $ML_TOOLKIT -eq 0 ]; then
  echo "No toolkit selected to build, nothing to do."
elif [ $CUDA_TOOLKIT -eq 1 ] && [ $ML_TOOLKIT -eq 1 ]; then
  echo "CUDA and ML toolkits can not be built simultaneously. Please choose one."
  exit 1
elif [ $CUDA_TOOLKIT -eq 1 ]; then
  if [[ "$TARGET" != "barebones" && "$TARGET" != "env-vars" ]]; then
    echo "Invalid target specified. Use 'barebones' or 'env-vars'."
    exit 1
  fi
  BUILD_FLAGS+=(--build-arg=ROS_DISTRO=$ROS_DISTRO)

  VERSION=$(cat "${SCRIPT_DIR}"/VERSION.cuda)-${TRT_IMAGE_TAG}
  IMAGE_NAME="ghcr.io/aica-technology/cuda-toolkit"
  TYPE="cuda"
elif [ $ML_TOOLKIT -eq 1 ]; then
  if [[ "$TARGET" != "cpu" && "$TARGET" != "gpu" ]]; then
    echo "Invalid target specified. Use 'cpu' or 'gpu'."
    exit 1
  fi

  POSTFIX=${TARGET}-${TRT_IMAGE_TAG}
  if [ $TORCH_VARIANT != $TARGET ]; then
    POSTFIX=${POSTFIX}-${TORCH_VARIANT}
  fi
  if [ $TORCH_VARIANT = "jetson" ]; then
    BUILD_FLAGS+=(--build-arg=TORCH_VERSION=$JETSON_TORCH_VERSION)
    BUILD_FLAGS+=(--build-arg=TORCH_SOURCE=$JETSON_TORCH_SOURCE)
    BUILD_FLAGS+=(--build-arg=TORCHVISION_VERSION=$JETSON_TORCHVISION_VERSION)
    BUILD_FLAGS+=(--build-arg=TORCHVISION_SOURCE=$JETSON_TORCHVISION_SOURCE)
    BUILD_FLAGS+=(--build-arg=TORCHAUDIO_VERSION=$JETSON_TORCHAUDIO_VERSION)
    BUILD_FLAGS+=(--build-arg=TORCHAUDIO_SOURCE=$JETSON_TORCHAUDIO_SOURCE)
  else
    BUILD_FLAGS+=(--build-arg=TORCH_VERSION=$TORCH_VERSION)
  fi
  VERSION=$(cat "${SCRIPT_DIR}"/VERSION.ml)-"${POSTFIX}"
  IMAGE_NAME="ghcr.io/aica-technology/ml-toolkit"
  TYPE="ml"

  BUILD_FLAGS+=(--build-arg=PYTHON_VERSION=${PYTHON_VERSION})
  BUILD_FLAGS+=(--build-arg=TORCH_VARIANT=${TORCH_VARIANT})
fi

BUILD_FLAGS+=(--target ${TARGET})
BUILD_FLAGS+=(--build-arg=UBUNTU_VERSION=${UBUNTU_VERSION})
BUILD_FLAGS+=(--build-arg=TENSORRT_IMAGE=${TENSORRT_IMAGE})
BUILD_FLAGS+=(--build-arg=TRT_IMAGE_TAG=${TRT_IMAGE_TAG})
BUILD_FLAGS+=(--build-arg=VERSION=${VERSION})
docker buildx build -f Dockerfile."${TYPE}" -t "${IMAGE_NAME}":v"${VERSION}" "${BUILD_FLAGS[@]}" .
