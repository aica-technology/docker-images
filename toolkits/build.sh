#!/bin/bash

TENSORRT_IMAGE=nvcr.io/nvidia/tensorrt
TRT_IMAGE_TAG=24.12-py3

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

CUDA_IMAGE_BASE="ghcr.io/aica-technology/toolkits/cuda"
ML_IMAGE_BASE="ghcr.io/aica-technology/toolkits/ml"

PLATFORM=""
MULTIARCH=0

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --cuda-toolkit)
    TYPE="cuda"
    shift 1
    ;;
  --ml-toolkit)
    TYPE="ml"
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

  --multiarch)
    if [ "$PLATFORM" ]; then
      echo "--multiarch can not be used when --platform is set." >&2
      exit 1
    fi
    MULTIARCH=1
    BUILD_FLAGS+=(--platform=linux/amd64,linux/arm64)
    shift 1
    ;;
  --platform)
    if [ "$MULTIARCH" -eq 1 ]; then
      echo "--platform can not be used when --multiarch is set." >&2
      exit 1
    fi
    if [ "$2" != "amd64" ] && [ "$2" != "arm64" ]; then
      echo "Invalid platform specified. Use 'amd64' or 'arm64'." >&2
      exit 1
    fi
    PLATFORM="$2"
    shift 2
    ;;
  --push)
    BUILD_FLAGS+=(--push)
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

generate_base_versions() {
  local version_file=$1
  RAW_VERSION=$(cat ${version_file})
  BASE_VERSION=${RAW_VERSION%%-*}
  RC_SUFFIX=${RAW_VERSION#"$BASE_VERSION"} # this may be empty if version is not a release candidate
  VERSION=${BASE_VERSION}"-"${VERSION_SUFFIX}${RC_SUFFIX}
}

if [ "$TYPE" = "cuda" ]; then
  echo "Building CUDA toolkit..."
  BUILD_FLAGS+=(--build-arg=ROS_DISTRO=$ROS_DISTRO)
elif [ "$TYPE" = "ml" ]; then
  echo "Building ML toolkit..."
else
  echo "Unknown toolkit type: $TYPE"
  exit 1
fi

if [ "$TYPE" = "ml" ]; then
  if [[ "$TARGET" != "cpu" && "$TARGET" != "gpu" && "$TARGET" != "jetson" ]]; then
    echo "Invalid target specified. Use 'cpu', 'gpu', or 'jetson'."
    exit 1
  fi

  BUILD_FLAGS+=(--build-arg=PYTHON_VERSION=${PYTHON_VERSION})
  if [ $TARGET = "jetson" ]; then
    BUILD_FLAGS+=(--build-arg=TORCH_VERSION=$JETSON_TORCH_VERSION)
    BUILD_FLAGS+=(--build-arg=TORCH_SOURCE=$JETSON_TORCH_SOURCE)
    BUILD_FLAGS+=(--build-arg=TORCHVISION_VERSION=$JETSON_TORCHVISION_VERSION)
    BUILD_FLAGS+=(--build-arg=TORCHVISION_SOURCE=$JETSON_TORCHVISION_SOURCE)
    BUILD_FLAGS+=(--build-arg=TORCHAUDIO_VERSION=$JETSON_TORCHAUDIO_VERSION)
    BUILD_FLAGS+=(--build-arg=TORCHAUDIO_SOURCE=$JETSON_TORCHAUDIO_SOURCE)
    BUILD_FLAGS+=(--build-arg=TARGET=${TARGET})
    BUILD_FLAGS+=(--target gpu)
  else
    BUILD_FLAGS+=(--build-arg=TARGET=${TARGET})
    BUILD_FLAGS+=(--build-arg=TORCH_VERSION=$TORCH_VERSION)
    BUILD_FLAGS+=(--target ${TARGET})
  fi
fi

# handle image name and versions
IMAGE_NAME=""
generate_base_versions "${SCRIPT_DIR}/VERSION.${TYPE}"

ALIASES=()
if [ "$TYPE" = "cuda"  ]; then
  IMAGE_NAME=$CUDA_IMAGE_BASE

  if [ "$TARGET" = "jetson" ]; then
    VERSION_SUFFIX="l4t"$(echo "$TRT_IMAGE_TAG" | cut -d'-' -f1)
    VERSION=${BASE_VERSION}"-"${VERSION_SUFFIX}${RC_SUFFIX}
    ALIASES+=("v"d$BASE_VERSION"-l4t"${RC_SUFFIX})
    ALIASES+=("l4t"${RC_SUFFIX})
  else
    VERSION_SUFFIX="cuda"$(echo "$TRT_IMAGE_TAG" | cut -d'-' -f1)
    VERSION=${BASE_VERSION}"-"${VERSION_SUFFIX}${RC_SUFFIX}
    ALIASES+=("v"$BASE_VERSION"-cuda"${RC_SUFFIX})
    ALIASES+=("cuda"${RC_SUFFIX})
  fi
else
  IMAGE_NAME=$ML_IMAGE_BASE

  if [ "$TARGET" = "jetson" ]; then
    VERSION_SUFFIX+="l4t"$(echo "$TRT_IMAGE_TAG" | cut -d'-' -f1)
    VERSION=${BASE_VERSION}"-"${VERSION_SUFFIX}${RC_SUFFIX}
    ALIASES+=("v"$BASE_VERSION"-jetson"${RC_SUFFIX})
    ALIASES+=("jetson"${RC_SUFFIX})
  else
    if [ "$TARGET" = "gpu" ]; then
      VERSION_SUFFIX+="$TARGET"$(echo "$TRT_IMAGE_TAG" | cut -d'-' -f1)
    else
      VERSION_SUFFIX+="$TARGET"$UBUNTU_VERSION
    fi
    VERSION=${BASE_VERSION}"-"${VERSION_SUFFIX}${RC_SUFFIX}
    ALIASES+=("v"$BASE_VERSION"-$TARGET"${RC_SUFFIX})
    ALIASES+=("$TARGET"${RC_SUFFIX})
  fi
fi

BUILD_FLAGS+=(--build-arg=UBUNTU_VERSION=${UBUNTU_VERSION})
BUILD_FLAGS+=(--build-arg=TENSORRT_IMAGE=${TENSORRT_IMAGE})
BUILD_FLAGS+=(--build-arg=TRT_IMAGE_TAG=${TRT_IMAGE_TAG})
BUILD_FLAGS+=(--build-arg=VERSION=${VERSION})

if [ "$MULTIARCH" -eq 0 ]; then
  if [ -z "$PLATFORM" ]; then
    PLATFORM=$(uname -m)
  fi
  if [ "$PLATFORM" = "amd64" ]; then
    PLATFORM="amd64"
  elif [ "$PLATFORM" = "arm64" ]; then
    PLATFORM="arm64"
  fi
  VERSION=$VERSION"-"$PLATFORM
  PLATFORMED_ALIASES=()
  for alias in "${ALIASES[@]}"; do
    PLATFORMED_ALIASES+=("$alias-$PLATFORM")
  done
  ALIASES=("${PLATFORMED_ALIASES[@]}")
  BUILD_FLAGS+=(--platform="linux/${PLATFORM}")
fi

echo "Building image with base \"${IMAGE_NAME}\" and version tags: "
TAGS=()
echo "  - v$VERSION"
for alias in "${ALIASES[@]}"; do
  echo "  - $alias (alias)"
  TAGS+=(-t "${IMAGE_NAME}:${alias}")
done

docker buildx build \
  -f "$SCRIPT_DIR/Dockerfile.${TYPE}" \
  -t "${IMAGE_NAME}:v${VERSION}" \
  "${TAGS[@]}" \
  "${BUILD_FLAGS[@]}" \
  .
