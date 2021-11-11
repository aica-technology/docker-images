#!/bin/bash

IMAGE_NAME=""
CONTAINER_NAME=""
USERNAME=""
GPUS=""
ROS_DOMAIN_ID=""
GENERATE_HOST_NAME=true

HELP_MESSAGE="
Usage: aica-docker interactive <image> [-n <name>] [-u <user>]

Run a docker container as an interactive shell.

Options:
  -i, --image <name>       Specify the name of the docker image.
                           (required)

  -n, --name <name>        Specify the name of generated container.
                           By default, this is deduced from
                           the image name, replacing all
                           '/' and ':' with '-' and appending
                           '-runtime'. For example, the image
                           aica-technology/ros2-ws:foxy would yield
                           aica-technology-ros2-ws-foxy-runtime

  -u, --user <user>        Specify the name of the login user.
                           (optional)

  --no-hostname            Suppress the automatic generation of a
                           hostname for the container. By default,
                           the container hostname is set to be
                           the same as the container name.

  --gpus <gpu_options>     Add GPU access for applications that
                           require hardware acceleration (e.g. Gazebo)
                           For the list of gpu_options parameters see:
    >>> https://docs.docker.com/config/containers/resource_constraints

  --ros-domain-id <id>     Set the ROS_DOMAIN_ID environment variable
                           to avoid conflicts when doing network discovery

  -h, --help               Show this help message.

Any additional arguments passed to this script are forwarded to
the 'docker run' command.
"

RUN_FLAGS=()
FWD_ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
  -i | --image)
    IMAGE_NAME=$2
    shift 2
    ;;
  -n | --name)
    CONTAINER_NAME=$2
    shift 2
    ;;
  --no-hostname)
    GENERATE_HOST_NAME=false
    shift 1
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

if [ -z "${IMAGE_NAME}" ]; then
  echo "No image name provided!"
  echo "${HELP_MESSAGE}"
  exit 1
fi

if [ -z "${CONTAINER_NAME}" ]; then
  CONTAINER_NAME="${IMAGE_NAME//[\/.]/-}"
  CONTAINER_NAME="${CONTAINER_NAME/:/-}-runtime"
fi

if [ -n "${USERNAME}" ]; then
  RUN_FLAGS+=(-u "${USERNAME}")
fi

if [ $GENERATE_HOST_NAME == true ]; then
  RUN_FLAGS+=(--hostname "${CONTAINER_NAME}")
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

if [[ "${OSTYPE}" == "darwin"* ]]; then
  RUN_FLAGS+=(-e DISPLAY=host.docker.internal:0)
else
  xhost +
  RUN_FLAGS+=(-e DISPLAY="${DISPLAY}")
  RUN_FLAGS+=(-e XAUTHORITY="${XAUTHORITY}")
  RUN_FLAGS+=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
  RUN_FLAGS+=(--device=/dev/dri:/dev/dri)
fi

if [ ${#FWD_ARGS[@]} -gt 0 ]; then
  echo "Forwarding additional arguments to docker run command:"
  echo "${FWD_ARGS[@]}"
fi

docker run -it --rm \
  "${RUN_FLAGS[@]}" \
  --name "${CONTAINER_NAME}" \
  "${FWD_ARGS[@]}" \
  "${IMAGE_NAME}" /bin/bash
