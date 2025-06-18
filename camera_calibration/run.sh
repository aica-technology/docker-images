VERSION=$(cat VERSION)
OUTPUT_DIR=calibration

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}

xhost +
docker run -it --rm \
    --device /dev/dri:/dev/dri \
    -e ROS_DOMAIN_ID="${ROS_DOMAIN_ID}" \
    -e DISPLAY="${DISPLAY}" \
    -e XAUTHORITY="${XAUTHORITY}" \
    -e CALIB_WIDTH=7 \
    -e CALIB_HEIGHT=9 \
    -e CALIB_SQUARE=0.015 \
    -e CALIB_TOPIC=/camera_streamer/image \
    -v $OUTPUT_DIR:/export \
    -v /dev:/dev:rw \
    --privileged \
    --net host \
    ghcr.io/aica-technology/camera_calibration:${VERSION}