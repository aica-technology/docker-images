ARG BASE_IMAGE=ghcr.io/eeberhard/ros2-modulo
ARG BASE_TAG=galactic
FROM ghcr.io/aica-technology/ros2-ws:galactic as ros2-control-sources-galactic
USER ${USER}

RUN mkdir -p ${ROS2_WORKSPACE}/src/ros2_control
WORKDIR ${ROS2_WORKSPACE}/src/ros2_control

RUN git clone -b 1.0.0 --depth 1 https://github.com/ros-controls/ros2_control.git
RUN git clone -b 1.0.0 --depth 1 https://github.com/ros-controls/ros2_controllers.git

# get additional interface dependencies manually
RUN git clone -b galactic-devel --depth 1 https://github.com/ros-controls/control_msgs.git
RUN git clone -b ros2-master --depth 1 https://github.com/ros-controls/control_toolbox.git
RUN git clone -b 2.1.1 --depth 1 https://github.com/ros-controls/realtime_tools.git
RUN git clone -b galactic --depth 1 https://github.com/ros2/rcl_interfaces.git
RUN git clone -b galactic --depth 1 https://github.com/ros2/test_interface_files.git
RUN git clone -b ros2 --depth 1 https://github.com/ros/angles.git


FROM ${BASE_IMAGE}:galactic as ros2-control-version-galactic
COPY --from=ros2-control-sources-galactic ${ROS2_WORKSPACE}/src/ros2_control/ ${ROS2_WORKSPACE}/src/


FROM ${BASE_IMAGE}:galactic-devel as ros2-control-version-galactic-devel
COPY --from=ros2-control-sources-galactic ${ROS2_WORKSPACE}/src/ros2_control/ ${ROS2_WORKSPACE}/src/


FROM ${BASE_IMAGE}:humble-devel as ros2-control-version-humble-devel
USER ${USER}

WORKDIR /home/${USER}/ros2_ws/src
RUN git clone -b 2.11.0 --depth 1 https://github.com/ros-controls/ros2_control.git
RUN git clone -b 2.11.0 --depth 1 https://github.com/ros-controls/ros2_controllers.git

# get additional interface dependencies manually
RUN git clone -b humble --depth 1 https://github.com/ros-controls/control_msgs.git
RUN git clone -b ros2-master --depth 1 https://github.com/ros-controls/control_toolbox.git
RUN git clone -b 2.2.0 --depth 1 https://github.com/ros-controls/realtime_tools.git
RUN git clone -b humble --depth 1 https://github.com/ros2/rcl_interfaces.git
RUN git clone -b humble --depth 1 https://github.com/ros2/test_interface_files.git
RUN git clone -b ros2 --depth 1 https://github.com/ros/angles.git
RUN git clone -b ros2 --depth 1 https://github.com/ros-drivers/ackermann_msgs.git


FROM ros2-control-version-${BASE_TAG} as final
ENV ROS2_WORKSPACE /home/${USER}/ros2_ws
WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
