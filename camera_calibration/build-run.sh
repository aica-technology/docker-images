#!/bin/bash

IMAGE_NAME=ghcr.io/aica-technology/camera_calibration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

VERSION=$(cat VERSION)
OUTPUT_DIR="${SCRIPT_DIR}"/calibration
CALIB_WIDTH=7
CALIB_HEIGHT=9
CALIB_SQUARE=0.015
CALIB_TOPIC=/camera_streamer/image

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  # build args
  -r | --rebuild)
    BUILD_FLAGS+=(--no-cache)
    shift 1
    ;;
  -v | --verbose)
    BUILD_FLAGS+=(--progress=plain)
    shift 1
    ;;

  # run args
  --calibration-width)
    CALIB_WIDTH=$2
    shift 2
    ;;
  --calibration-height)
    CALIB_HEIGHT=$2
    shift 2
    ;;
  --calibration-square)
    CALIB_SQUARE=$2
    shift 2
    ;;
  --calibration-topic)
    CALIB_TOPIC=$2
    shift 2
    ;;
  --output-dir)
    OUTPUT_DIR=$2
    shift 2
    ;;

  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
echo "Using ROS_DOMAIN_ID: ${ROS_DOMAIN_ID}"

docker buildx build -t "${IMAGE_NAME}":v"${VERSION}" "${BUILD_FLAGS[@]}" .

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

xhost +
docker run -it --rm \
    --device /dev/dri:/dev/dri \
    -u ros2 \
    -e ROS_DOMAIN_ID="${ROS_DOMAIN_ID}" \
    -e DISPLAY="${DISPLAY}" \
    -e XAUTHORITY="${XAUTHORITY}" \
    -e CALIB_WIDTH="${CALIB_WIDTH}" \
    -e CALIB_HEIGHT="${CALIB_HEIGHT}" \
    -e CALIB_SQUARE="${CALIB_SQUARE}" \
    -e CALIB_TOPIC=${CALIB_TOPIC} \
    -v $OUTPUT_DIR:/export \
    -v /dev:/dev:rw \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --privileged \
    --net host \
    --name camera_calibration \
    "${IMAGE_NAME}":v"${VERSION}"