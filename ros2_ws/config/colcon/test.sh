#!/bin/bash

HELP_MESSAGE="
Helper function around colcon test to test selected packages
more easily. Use with positional arguments to test only the
listed packages, or with no positional arguments to test the
whole workspace. Supply the following flags to modify the test.

Any additional flags are forwarded to colcon test.

-c | --cd               Temporarily change into the COLCON_WORKSPACE
                        directory when testing
                        (workspace path: ${COLCON_WORKSPACE})

-h | --help             Show this help message.
"

CHANGE_DIR=false
PACKAGES=()
TEST_ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  -c | --cd)
    CHANGE_DIR=true
    shift 1
    ;;
  -h | --help)
    echo "${HELP_MESSAGE}"
    exit 0
    ;;
  -*)
    TEST_ARGS+=($1)
    shift 1
    ;;
  *)
    PACKAGES+=($1)
    shift 1
    ;;
  esac
done

CURRENT_DIR=$(pwd)

colcon_test_packages () {
  if [ "${CHANGE_DIR}" == true ]; then
    cd "${COLCON_WORKSPACE}"
  fi
  if [ ${#PACKAGES[@]} -gt 0 ]; then
    colcon test --packages-select "${PACKAGES[@]}" "${TEST_ARGS[@]}"
  else
    colcon test "${TEST_ARGS[@]}"
  fi
  cd "${CURRENT_DIR}"
  colcon test-result --verbose
}

colcon_test_packages || cd "${CURRENT_DIR}"
