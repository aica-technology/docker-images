ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-control-libraries
ARG BASE_TAG=humble
FROM ${BASE_IMAGE}:${BASE_TAG} as modulo-build

ARG MODULO_BRANCH=main
WORKDIR /tmp
RUN git clone -b ${MODULO_BRANCH} --depth 1 https://github.com/aica-technology/modulo.git

# copy sources and build ROS workspace with user permissions
RUN cp -r /tmp/modulo/source ${ROS2_WORKSPACE}/src/modulo

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"

RUN sudo rm -rf /tmp/*

FROM ${BASE_IMAGE}:${BASE_TAG} as final
COPY --from=modulo-build ${ROS2_WORKSPACE} ${ROS2_WORKSPACE}