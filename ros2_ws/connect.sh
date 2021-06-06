#!/bin/bash

CONTAINER_NAME=aica-technology-ros2-ws-foxy-ssh
USERNAME=ros2

HELP_MESSAGE="Usage: ./connect.sh [-n <container>] [-u <username>]

Connect an interactive terminal shell to a running container.

Options:
  -n, --name <container>   Specify the container.
                           (default: ${CONTAINER_NAME})

  -u, --user <username>    Specify the login username.
                           (default: ${USERNAME})

  -h, --help               Show this help message."

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--name) CONTAINER_NAME=$2; shift 2;;
    -u|--user) USERNAME=$2; shift 2;;
    -h|--help) echo "${HELP_MESSAGE}"; exit 0;;
    *) echo "Unknown option: $1" >&2; echo "${HELP_MESSAGE}"; exit 1;;
  esac
done

BUILD_FLAGS=()
BUILD_FLAGS+=(-u "${USERNAME}")
if [[ "$OSTYPE" == "darwin"* ]]; then
  DISPLAY_IP=$(ifconfig en0 | grep "inet" | cut -d\  -f2)
  BUILD_FLAGS+=(-e DISPLAY="${DISPLAY_IP}")
else
  xhost +
  BUILD_FLAGS+=(-e DISPLAY="${DISPLAY}")
  BUILD_FLAGS+=(-e XAUTHORITY="${XAUTH}")
  BUILD_FLAGS+=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
  BUILD_FLAGS+=(-v "${XAUTH}:${XAUTH}")
fi

docker container exec -it "${BUILD_FLAGS[@]}" "${CONTAINER_NAME}" /bin/bash
