#!/bin/bash

DEFAULT_WIDTH=7
DEFAULT_HEIGHT=9
DEFAULT_SQUARE=0.015
DEFAULT_TOPIC="/camera_streamer/image"

WIDTH="${CALIB_WIDTH:-$DEFAULT_WIDTH}"
HEIGHT="${CALIB_HEIGHT:-$DEFAULT_HEIGHT}"
SQUARE="${CALIB_SQUARE:-$DEFAULT_SQUARE}"
TOPIC="${CALIB_TOPIC:-$DEFAULT_TOPIC}"

ros2 run camera_calibration cameracalibrator \
  --size ${WIDTH}x${HEIGHT} \
  --square ${SQUARE} \
  --no-service-check \
  --ros-args -r image:=${TOPIC}