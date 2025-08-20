#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

VERSION=$(cat VERSION)
MODEL="yolo12n.pt"

while [ "$#" -gt 0 ]; do
  case "$1" in
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

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

xhost +
docker run --rm -it \
    -e model="${MODEL}" \
    -v .:/exports \
    --name yolo_model_converter \
    ghcr.io/aica-technology/yolo_model_converter:v${VERSION}