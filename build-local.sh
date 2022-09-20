#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CURRENT_DIR="$(pwd)"

BASE_TAG=humble
OUTPUT_TAG=humble-devel
CL_BRANCH=develop
MODULO_BRANCH=develop

BUILD_FLAGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  --base-tag)
    BASE_TAG=$2
    shift 2
    ;;
  --output-tag)
    OUTPUT_TAG=$2
    shift 2
    ;;
  --cl-branch)
    CL_BRANCH=$2
    shift 2
    ;;
  --modulo-branch)
    MODULO_BRANCH=$2
    shift 2
    ;;
  -*)
    BUILD_FLAGS+=($1)
    shift 1
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

cd "${SCRIPT_DIR}"/ros2_ws && bash ./build.sh --base-tag "${BASE_TAG}" "${BUILD_FLAGS[@]}" || exit 1

cd "${SCRIPT_DIR}"/ros2_control_libraries && bash ./build.sh --local-base --cl-branch "${CL_BRANCH}" \
  --base-tag "${BASE_TAG}" --output-tag "${OUTPUT_TAG}" "${BUILD_FLAGS[@]}" || exit 1

cd "${SCRIPT_DIR}"/ros2_modulo && bash ./build.sh --local-base --modulo-branch "${MODULO_BRANCH}" \
  --base-tag "${OUTPUT_TAG}" --output-tag "${OUTPUT_TAG}" "${BUILD_FLAGS[@]}" || exit 1

cd "${SCRIPT_DIR}"/ros2_modulo_control && bash ./build.sh --local-base \
  --base-tag "${OUTPUT_TAG}" --output-tag "${OUTPUT_TAG}" "${BUILD_FLAGS[@]}" || exit 1

cd "${CURRENT_DIR}"
