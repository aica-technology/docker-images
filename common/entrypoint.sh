#!/usr/bin/env bash
set -e

if [ $(id -u) -ne 0 ]; then
  echo "Fixing UID, this can take a few moments..."
  eval $( fixuid -q )
fi

# setup ros2 environment
source "/opt/ros/$ROS_DISTRO/setup.bash" --
exec "$@"
