#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

TYPE=("cuda" "ml")
TARGETS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --cuda-toolkit)
    TYPE=("cuda")
    shift 1
    ;;
  --ml-toolkit)
    TYPE=("ml")
    shift 1
    ;;
  --target)
    if [[ "$TARGET" != "cpu" && "$TARGET" != "gpu" && "$TARGET" != "jetson" ]]; then
      echo "Invalid target specified. Use 'cpu', 'gpu', or 'jetson'."
      exit 1
    fi
    TARGETS=("$TARGET")
    shift 2
    ;;
  esac
done

echo $SCRIPT_DIR

for type in "${TYPE[@]}"; do
  echo "Building $type toolkit..."

  if [ "$type" = "cuda" ]; then
    if [ ${#TARGETS[@]} -eq 0 ]; then
      TARGETS=("default" "jetson")
    fi

    for target in "${TARGETS[@]}"; do
      echo "Building for target: $target"
      if [ "$target" = "jetson" ]; then
        echo "Building for Jetson..."
        bash $SCRIPT_DIR/../toolkits/build.sh --cuda-toolkit  \
          --target jetson \
          --ubuntu-version 22.04 \
          --python-version 3.10 \
          --tensorrt-image nvcr.io/nvidia/l4t-tensorrt \
          --tensorrt-image-tag r8.6.2-devel \
          --push
      else
        echo "Building for generic platform..."
        bash $SCRIPT_DIR/../toolkits/build.sh --cuda-toolkit --push
      fi
    done
  elif [ "$type" = "ml" ]; then
    if [ ${#TARGETS[@]} -eq 0 ]; then
      TARGETS=("cpu" "gpu" "jetson")
    fi

    for target in "${TARGETS[@]}"; do
      if [ "$target" = "jetson" ]; then
        echo "Building for Jetson..."
        bash $SCRIPT_DIR/../toolkits/build.sh --ml-toolkit \
          --target jetson \
          --ubuntu-version 22.04 \
          --python-version 3.10 \
          --tensorrt-image nvcr.io/nvidia/l4t-tensorrt \
          --tensorrt-image-tag r8.6.2-devel \
          --push
      elif [ "$target" = "cpu" ]; then
        echo "Building for CPU..."
        $SCRIPT_DIR/../toolkits/build.sh --ml-toolkit --target cpu --push
      elif [ "$target" = "gpu" ]; then
        echo "Building for GPU..."
        $SCRIPT_DIR/../toolkits/build.sh --ml-toolkit --target gpu --push
      fi
    done
  fi
