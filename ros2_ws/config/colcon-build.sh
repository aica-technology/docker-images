#!/bin/bash

HELP_MESSAGE="
Helper function around colcon build to build selected packages
more easily. Use with positional arguments to build only the
listed packages, or with no positional arguments to build the
whole workspace. Supply the following flags to modify the build.

Any additional flags are forwarded to colcon build.

-d | --debug            Set CMAKE_BUILD_TYPE to Debug.
-o | --override         Add --allow-overriding for listed packages
-h | --help             Show this help message.
"

OVERRIDE=false
PACKAGES=()
BUILD_ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  -d | --debug)
    BUILD_ARGS+=("--cmake-args -DCMAKE_BUILD_TYPE=Debug")
    shift 1
    ;;
  -o | --override)
    OVERRIDE=true
    shift 1
    ;;
  -h | --help)
    echo "${HELP_MESSAGE}"
    exit 0
    ;;
  -*)
    BUILD_ARGS+=($1)
    shift 1
    ;;
  *)
    PACKAGES+=($1)
    shift 1
    ;;
  esac
done

# build selected packages only if they are supplied, otherwise do a generic build
if [ ${#PACKAGES[@]} -gt 0 ]; then
  if [ "${OVERRIDE}" == true ]; then
    BUILD_ARGS+=(--allow-overriding "${PACKAGES[@]}")
  fi
  colcon build --packages-select "${PACKAGES[@]}" "${BUILD_ARGS[@]}"
else
  colcon build "${BUILD_ARGS[@]}"
fi
