#!/bin/bash

CONTAINER_NAME=""
USERNAME=root

HELP_MESSAGE="
Usage: aica-docker connect <container> [-u <username>]

Connect an interactive terminal shell to a running container.
The container name is required and can be provided either as
a positional argument or explicitly with the -n|--name option.

Options:
  -n, --name <container>   Specify the container name.
                           (required)

  -u, --user <username>    Specify the login username.
                           (default: ${USERNAME})

  -h, --help               Show this help message.

Any additional arguments passed to this script are forwarded to
the 'docker container exec' command.
"

FWD_ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  -n | --name)
    CONTAINER_NAME=$2
    shift 2
    ;;
  -u | --user)
    USERNAME=$2
    shift 2
    ;;
  -h | --help)
    echo "${HELP_MESSAGE}"
    exit 0
    ;;
  *)
    if [ -z "${CONTAINER_NAME}" ]; then
      CONTAINER_NAME=$1
    else
      FWD_ARGS+=("$1")
    fi
    shift 1
    ;;
  esac
done

if [ -z "$CONTAINER_NAME" ]; then
  CONTAINERS="$(docker ps --format "{{.Names}}")"

  if [ -z "$CONTAINERS" ]; then
    echo "No running containers found!"
    exit 1
  else
    echo "Enter the ID of the container to which to connect:"
  fi
  # shellcheck disable=SC2206
  CONTAINERS=($CONTAINERS)

  INDEX=0
  for CONTAINER in "${CONTAINERS[@]}"; do
    :
    INDEX=$((INDEX + 1))
    echo "$INDEX: $CONTAINER"
  done

  read -r INPUT
  if [[ -n ${INPUT//[0-9]/} || "$INPUT" -le 0 || "$INPUT" -gt "$INDEX" ]]; then
      echo "Invalid input!"
      exit 1
  fi

  CONTAINER_NAME=${CONTAINERS[$((INPUT - 1))]}
  echo "Using container $CONTAINER_NAME"
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

if [ ${#FWD_ARGS[@]} -gt 0 ]; then
  echo "Forwarding additional arguments to docker container exec command:"
  echo "${FWD_ARGS[@]}"
fi

docker container exec -it "${EXEC_FLAGS[@]}" "${FWD_ARGS[@]}" "${CONTAINER_NAME}" /bin/bash
