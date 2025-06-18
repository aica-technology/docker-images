VERSION=$(cat VERSION)
OUTPUT_DIR=calibration
CALIB_WIDTH=7
CALIB_HEIGHT=9
CALIB_SQUARE=0.015

ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
echo "Using ROS_DOMAIN_ID: ${ROS_DOMAIN_ID}"

while [ "$#" -gt 0 ]; do
  case "$1" in
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
    -e CALIB_TOPIC=/camera_streamer/image \
    -v $OUTPUT_DIR:/export \
    -v /dev:/dev:rw \
    --privileged \
    --net host \
    --name camera_calibration \
    ghcr.io/aica-technology/camera_calibration:${VERSION}