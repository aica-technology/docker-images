#!/bin/bash

CONTAINER_NAME=""
USERNAME=root

HELP_MESSAGE="Usage: ./connect.sh <container> [-u <username>]

Connect an interactive terminal shell to a running container.
The container name is required and can be provided either as
a positional argument or explicitly with the -n|--name option.

Options:
  -n, --name <container>   Specify the container name.
                           (required)

  -u, --user <username>    Specify the login username.
                           (default: ${USERNAME})

  -h, --help               Show this help message."

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--name) CONTAINER_NAME=$2; shift 2;;
    -u|--user) USERNAME=$2; shift 2;;
    -h|--help) echo "${HELP_MESSAGE}"; exit 0;;
    -*) echo "Unknown option: $1" >&2; echo "${HELP_MESSAGE}"; exit 1;;
    *) CONTAINER_NAME=$1; shift 1;;
  esac
done

if [ -z "$CONTAINER_NAME" ]; then
  echo "No container name provided!"
  echo "${HELP_MESSAGE}"
  exit 1
fi

EXEC_FLAGS=()
EXEC_FLAGS+=(-u "${USERNAME}")
if [[ "$OSTYPE" == "darwin"* ]]; then
  EXEC_FLAGS+=(-e DISPLAY=host.docker.internal:0)
else
  xhost +
  EXEC_FLAGS+=(-e DISPLAY="${DISPLAY}")
  EXEC_FLAGS+=(-e XAUTHORITY="${XAUTH}")
fi

docker container exec -it "${EXEC_FLAGS[@]}" "${CONTAINER_NAME}" /bin/bash
