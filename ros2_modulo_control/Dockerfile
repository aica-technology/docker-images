ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-modulo
ARG ROS_VERSION=foxy
FROM ${BASE_IMAGE}:${ROS_VERSION} as base
USER ${USER}
ENV ROS2_WORKSPACE /home/${USER}/ros2_ws


FROM base as ros2-control-version-foxy

RUN sudo apt-get update && sudo apt-get install -y \
  ros-${ROS_DISTRO}-ros2-control \
  ros-${ROS_DISTRO}-ros2-controllers \
  && sudo ldconfig \
  && sudo rm -rf /var/lib/apt/lists/*


FROM base as ros2-control-version-galactic
ARG ROS2_CONTROL_TAG=1.0.0
WORKDIR ${ROS2_WORKSPACE}/src
RUN git clone -b ${ROS2_CONTROL_TAG} --depth 1 https://github.com/ros-controls/ros2_control.git
RUN git clone -b ${ROS2_CONTROL_TAG} --depth 1 https://github.com/ros-controls/ros2_controllers.git

# get additional interface dependencies manually
RUN git clone -b galactic-devel --depth 1 https://github.com/ros-controls/control_msgs.git
RUN git clone -b ros2-master --depth 1 https://github.com/ros-controls/control_toolbox.git
RUN git clone -b 2.1.1 --depth 1 https://github.com/ros-controls/realtime_tools.git
RUN git clone -b galactic --depth 1 https://github.com/ros2/rcl_interfaces.git
RUN git clone -b galactic --depth 1 https://github.com/ros2/test_interface_files.git
RUN git clone -b ros2 --depth 1 https://github.com/ros/angles.git

ENV ROSDEP_SKIP_KEYS="\
ros2_control \
ros-galactic-controller-interface \
ros-galactic-controller-manager \
ros-galactic-hardware-interface \
ros-galactic-ros2-controllers "


#WORKDIR ${ROS2_WORKSPACE}
#RUN rosdep update \
#  && rosdep install --from-paths src/rcl_interfaces --ignore-src -r -y \
#  && sudo rm -rf /var/lib/apt/lists/*

ARG ROS_VERSION=foxy
FROM ros2-control-version-foxy AS final
WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
