#!/bin/bash

DEFAULT_WIDTH=10
DEFAULT_HEIGHT=7
DEFAULT_SQUARE=0.015
DEFAULT_TOPIC="/camera_streamer/image"
DEFAULT_KCOEFF=3

WIDTH="${CALIB_WIDTH:-$DEFAULT_WIDTH}"
HEIGHT="${CALIB_HEIGHT:-$DEFAULT_HEIGHT}"
SQUARE="${CALIB_SQUARE:-$DEFAULT_SQUARE}"
TOPIC="${CALIB_TOPIC:-$DEFAULT_TOPIC}"
KCOEFF="${CALIB_KCOEFF:-$DEFAULT_KCOEFF}"

ros2 run camera_calibration cameracalibrator \
  --size ${WIDTH}x${HEIGHT} \
  --square ${SQUARE} \
  --no-service-check \
  --fix-principal-point \
  --fix-aspect-ratio \
  --zero-tangent-dist \
  --k-coefficients=${KCOEFF} \
  --ros-args -r image:=${TOPIC}