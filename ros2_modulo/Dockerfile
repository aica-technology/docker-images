ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-control-libraries
ARG ROS_VERSION=foxy
FROM ${BASE_IMAGE}:${ROS_VERSION}

ARG MODULO_BRANCH=main
WORKDIR /tmp
RUN git clone -b ${MODULO_BRANCH} --depth 1 https://github.com/epfl-lasa/modulo.git

# copy sources and build ROS workspace with user permissions
RUN cp -r /tmp/modulo/source/ ${ROS2_WORKSPACE}/src

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"

RUN rm -rf /tmp/*
