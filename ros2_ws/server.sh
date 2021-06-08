#!/bin/bash

SSH_PORT=3333
SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
IMAGE_NAME=aica-technology/ros2-ws:foxy
USERNAME=ros2

HELP_MESSAGE="
Usage: ./server.sh [-i <image>] [-p <port>] [-k <file>] [-n <name>] [-u <user>]

Run a docker container as an SSH server for remote development
from a docker image based on the ros2_ws image.

The server is bound to the specified port on localhost (127.0.0.1)
and uses passwordless RSA key-pair authentication. The host public key
is read from the specified key file and copied to the server on startup.

On linux hosts, the UID and GID of the specified user will also be
set to match the UID and GID of the host user by the entry script.

Options:
  -i, --image <name>       Specify the name of the docker image.
                           This must be based on the ros2_ws
                           image with the /sshd_entrypoint.sh
                           file and configurations intact.
                           (default: ${IMAGE_NAME})

  -p, --port <XXXX>        Specify the port to bind for SSH
                           connection.
                           (default: ${SSH_PORT})

  -k, --key-file <path>    Specify the path of the RSA
                           public key file on the local host.
                           (default: ${SSH_KEY_FILE})

  -n, --name <name>        Specify the name of generated container.
                           By default, this is deduced from
                           the image name, replacing all
                           '/' and ':' with '-' and appending
                           '-ssh'. For example, the image
                           aica-technology/ros2-ws:foxy would yield the name
                           aica-technology-ros2-ws-foxy-ssh

  -u, --user <user>        Specify the name of the remote user.
                           (default: ${USERNAME})

  -h, --help               Show this help message."

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p|--port) SSH_PORT=$2; shift 2;;
    -k|--key-file) SSH_KEY_FILE=$2; shift 2;;
    -i|--image) IMAGE_NAME=$2; shift 2;;
    -n|--name) CONTAINER_NAME=$2; shift 2;;
    -u|--user) USERNAME=$2; shift 2;;
    -h|--help) echo "${HELP_MESSAGE}"; exit 0;;
    *) echo "Unknown option: $1" >&2; echo "${HELP_MESSAGE}"; exit 1;;
  esac
done

CONTAINER_NAME="${IMAGE_NAME/\//-}"
CONTAINER_NAME="${CONTAINER_NAME/:/-}-ssh"

PUBLIC_KEY=$(cat "${SSH_KEY_FILE}")

COMMAND_FLAGS=()
COMMAND_FLAGS+=(--key "${PUBLIC_KEY}")
COMMAND_FLAGS+=(--user "${USERNAME}")

RUN_FLAGS=()
if [[ "$OSTYPE" != "darwin"* ]]; then
  UID=$(id -u "${USER}")
  GID=$(id -g "${USER}")
  COMMAND_FLAGS+=(--uid "${UID}")
  COMMAND_FLAGS+=(--gid "${GID}")

  RUN_FLAGS+=(--volume=/tmp/.X11-unix:/tmp/.X11-unix:rw)
  RUN_FLAGS+=(--volume="${XAUTH}:${XAUTH}")
fi

docker container stop "$CONTAINER_NAME" >/dev/null 2>&1
docker rm --force "$CONTAINER_NAME" >/dev/null 2>&1

echo "Starting background container with access port ${SSH_PORT} for user ${USERNAME}"
docker run -d --rm --cap-add sys_ptrace \
  --publish 127.0.0.1:"${SSH_PORT}":22 \
  --name "${CONTAINER_NAME}" \
  --hostname "${CONTAINER_NAME}" \
  "${RUN_FLAGS[@]}" \
  "${IMAGE_NAME}" /sshd_entrypoint.sh "${COMMAND_FLAGS[@]}"

echo "${CONTAINER_NAME}"
