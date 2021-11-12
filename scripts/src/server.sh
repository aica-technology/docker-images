#!/bin/bash

SSH_PORT=3333
SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
IMAGE_NAME=""
USERNAME=root
GPUS=""
ROS_DOMAIN_ID=14

HELP_MESSAGE="
Usage: aica-docker server <image> [-p <port>] [-k <file>] [-n <name>] [-u <user>]

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
                           (required)

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
                           aica-technology/ros2-ws:foxy would yield
                           aica-technology-ros2-ws-foxy-ssh

  -u, --user <user>        Specify the name of the remote user.
                           (default: ${USERNAME})

  --gpus <gpu_options>     Add GPU access for applications that
                           require hardware acceleration (e.g. Gazebo)
                           For the list of gpu_options parameters see:
    >>> https://docs.docker.com/config/containers/resource_constraints/

  --ros-domain-id <id>     Set the ROS_DOMAIN_ID environment variable
                           to avoid conflicts when doing network discovery.

  -h, --help               Show this help message.

Any additional arguments passed to this script are forwarded to
the 'docker run' command.
"

CONTAINER_NAME=""
CUSTOM_SSH_PORT=""

FWD_ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  -p | --port)
    # only capture the port argument for SSH
    # the first time, otherwise forward it
    if [ -z "${CUSTOM_SSH_PORT}" ]; then
      CUSTOM_SSH_PORT=$2
    else
      FWD_ARGS+=("$1 $2")
    fi
    shift 2
    ;;
  -k | --key-file)
    SSH_KEY_FILE=$2
    shift 2
    ;;
  -i | --image)
    IMAGE_NAME=$2
    shift 2
    ;;
  -n | --name)
    CONTAINER_NAME=$2
    shift 2
    ;;
  -u | --user)
    USERNAME=$2
    shift 2
    ;;
  --gpus)
    GPUS=$2
    shift 2
    ;;
  --ros-domain-id)
    ROS_DOMAIN_ID=$2
    shift 2
    ;;
  -h | --help)
    echo "${HELP_MESSAGE}"
    exit 0
    ;;
  *)
    if [ -z "${IMAGE_NAME}" ]; then
      IMAGE_NAME=$1
    else
      FWD_ARGS+=("$1")
    fi
    shift 1
    ;;
  esac
done

if [ -n "$CUSTOM_SSH_PORT" ]; then
  SSH_PORT="${CUSTOM_SSH_PORT}"
fi

if [ -z "$IMAGE_NAME" ]; then
  echo "No image name provided!"
  echo "${HELP_MESSAGE}"
  exit 1
fi

if [ -z "$CONTAINER_NAME" ]; then
  CONTAINER_NAME="${IMAGE_NAME//[\/.]/-}"
  CONTAINER_NAME="${CONTAINER_NAME/:/-}-ssh"
fi

PUBLIC_KEY=$(cat "${SSH_KEY_FILE}")

COMMAND_FLAGS=()
COMMAND_FLAGS+=(--key "${PUBLIC_KEY}")
COMMAND_FLAGS+=(--user "${USERNAME}")

RUN_FLAGS=()
if [[ "$OSTYPE" != "darwin"* ]]; then
  USER_ID=$(id -u "${USER}")
  GROUP_ID=$(id -g "${USER}")
  COMMAND_FLAGS+=(--uid "${USER_ID}")
  COMMAND_FLAGS+=(--gid "${GROUP_ID}")

  RUN_FLAGS+=(--volume=/tmp/.X11-unix:/tmp/.X11-unix:rw)
  RUN_FLAGS+=(--device=/dev/dri:/dev/dri)
fi

if [ -n "${GPUS}" ]; then
  RUN_FLAGS+=(--gpus "${GPUS}")
  RUN_FLAGS+=(--env DISPLAY="${DISPLAY}")
  RUN_FLAGS+=(--env NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES:-all}")
  RUN_FLAGS+=(--env NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics")
fi

if [ -n "${ROS_DOMAIN_ID}" ]; then
  RUN_FLAGS+=(--env ROS_DOMAIN_ID="${ROS_DOMAIN_ID}")
fi

docker container stop "$CONTAINER_NAME" >/dev/null 2>&1
docker rm --force "$CONTAINER_NAME" >/dev/null 2>&1

if [ ${#FWD_ARGS[@]} -gt 0 ]; then
  echo "Forwarding additional arguments to docker run command:"
  echo "${FWD_ARGS[@]}"
fi

echo "Starting background container with access port ${SSH_PORT} for user ${USERNAME}"
docker run -d --rm --cap-add sys_ptrace \
  --user root \
  --publish 127.0.0.1:"${SSH_PORT}":22 \
  --name "${CONTAINER_NAME}" \
  --hostname "${CONTAINER_NAME}" \
  "${RUN_FLAGS[@]}" \
  "${FWD_ARGS[@]}" \
  "${IMAGE_NAME}" /sshd_entrypoint.sh "${COMMAND_FLAGS[@]}"

echo "${CONTAINER_NAME}"
