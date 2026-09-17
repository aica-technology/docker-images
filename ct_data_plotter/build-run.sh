#!/bin/bash

IMAGE_NAME=ghcr.io/aica-technology/ct_data_plotter
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
VERSION=$(cat "${SCRIPT_DIR}/VERSION")

OUTPUT_DIR="${SCRIPT_DIR}/export"
OUTPUT_NAME="plot.png"
BAG_PATH=""

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  # build args
  -r | --rebuild)
    BUILD_FLAGS+=(--no-cache)
    shift 1
    ;;
  
  # run args
  --bag-path)
    BAG_PATH=$2
    shift 2
    ;;
  --output-dir)
    OUTPUT_DIR=$2
    shift 2
    ;;
  --output-name)
    OUTPUT_NAME=$2
    shift 2
    ;;

  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [ -z "$BAG_PATH" ]; then
    echo "Error: You must provide a bag path."
    echo "Usage: $0 --bag-path /path/to/rosbag/dir [options]"
    exit 1
fi

docker buildx build --load -t "${IMAGE_NAME}":v"${VERSION}" "${BUILD_FLAGS[@]}" "${SCRIPT_DIR}"

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

xhost +
docker run -it --rm \
    --device /dev/dri:/dev/dri \
    -u ros2 \
    -e DISPLAY="${DISPLAY}" \
    -e XAUTHORITY="${XAUTHORITY}" \
    -e ROSBAG_PATH="/bag" \
    -v "$OUTPUT_DIR":/export \
    -v "$BAG_PATH":/bag:ro \
    -v /dev:/dev:rw \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --privileged \
    --net host \
    --name ct_data_plotter \
    "${IMAGE_NAME}":v"${VERSION}" \
    python3 /usr/local/bin/plot.py /bag --save /export/"$OUTPUT_NAME"
