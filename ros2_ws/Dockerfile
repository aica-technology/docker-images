ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ${BASE_IMAGE}:${BASE_TAG} AS environment-variables
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=ros2
ENV HOME=/home/${USER}
ENV ROS2_WORKSPACE=/home/${USER}/ros2_ws
ENV COLCON_HOME=${HOME}/.colcon


FROM environment-variables AS base-dependencies

# disable suggested and recommended install
RUN apt-config dump | grep -we Recommends -e Suggests | sed s/1/0/ \
    | sudo tee /etc/apt/apt.conf.d/999norecommend

# install base dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    rsync \
    software-properties-common \
    ssh \
    unzip \
    wget \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Set disable_coredump false" >> /etc/sudo.conf

FROM base-dependencies AS base-user-iron

# create and configure a new user
RUN addgroup --gid 1000 ${USER}
RUN adduser --gecos "ROS2 User" --uid 1000 --gid 1000 ${USER} && yes | passwd ${USER}

FROM base-dependencies AS base-user-jazzy

# rename existing ubuntu user
RUN usermod -l ${USER} ubuntu
RUN groupmod -n ${USER} ubuntu
RUN usermod -d ${HOME} -m ros2
RUN chfn -f "ROS2 User" ros2

FROM base-user-${ROS_DISTRO} AS base-workspace

RUN usermod -a -G dialout ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_aptget
RUN chmod 0440 /etc/sudoers.d/99_aptget && chown root:root /etc/sudoers.d/99_aptget

# configure colcon defaults and utilities
USER ${USER}
WORKDIR ${HOME}
COPY --chown=${USER}:${USER} ./config/camera_calibration.sh /usr/local/bin/camera_calibration
RUN mkdir -p ${COLCON_HOME}
COPY --chown=${USER}:${USER} ./config/colcon ${COLCON_HOME}
RUN /bin/bash ${COLCON_HOME}/setup.sh

# build ROS workspace
RUN mkdir -p ${ROS2_WORKSPACE}/src
WORKDIR ${ROS2_WORKSPACE}
RUN rosdep update
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build --symlink-install"

# prepend the environment sourcing to bashrc (appending will fail for non-interactive sessions)
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash; \
    source ${ROS2_WORKSPACE}/install/setup.bash" | cat - ${HOME}/.bashrc > tmp && mv tmp ${HOME}/.bashrc
# enable colorized output from ros logging
RUN echo "export RCUTILS_COLORIZED_OUTPUT=1" >> ${HOME}/.bashrc

WORKDIR ${ROS2_WORKSPACE}
<<<<<<< HEAD
FROM base-workspace AS ros2-control-jazzy
RUN apt-get update && apt-get install --no-install-recommends -y \
    libcap-dev \
    python3-jinja2 \
    python3-typeguard \
    && rm -rf /var/lib/apt/lists/*
=======
FROM base-workspace AS ros2-ws
>>>>>>> 4ee4019 (fix: reduce Dockerfile operations)

# build as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}/src

<<<<<<< HEAD
RUN git clone -b 4.24.0 --depth 1 https://github.com/ros-controls/ros2_control.git
RUN git clone -b 4.19.0 --depth 1 https://github.com/ros-controls/ros2_controllers.git
# get additional interface dependencies manually
RUN git clone -b 5.3.0 --depth 1 https://github.com/ros-controls/control_msgs.git
RUN git clone -b 1.0.6 --depth 1 https://github.com/pal-robotics/backward_ros.git
RUN git clone -b 4.3.1 --depth 1 https://github.com/ros/diagnostics.git
RUN git clone -b 3.1.0 --depth 1 https://github.com/ros-controls/realtime_tools.git
RUN git clone -b 2.2.0 --depth 1 https://github.com/ros2/rcl_interfaces.git
RUN git clone -b 0.13.0 --depth 1 https://github.com/ros2/test_interface_files.git
RUN git clone -b 0.13.0 --depth 1 https://github.com/ros2/example_interfaces.git
RUN git clone -b 1.16.0 --depth 1 https://github.com/ros/angles.git
RUN git clone -b 2.0.2 --depth 1 https://github.com/ros-drivers/ackermann_msgs.git
RUN git clone -b 0.3.9 --depth 1 https://github.com/PickNikRobotics/generate_parameter_library.git
RUN git clone -b 1.1.0 --depth 1 https://github.com/PickNikRobotics/RSL.git
RUN git clone -b 1.0.2 --depth 1 https://github.com/PickNikRobotics/cpp_polyfills.git
RUN git clone -b 3.4.0 --depth 1 https://github.com/ros-controls/control_toolbox.git
RUN git clone -b 2.1.2 --depth 1 https://github.com/ros/filters.git
RUN git clone -b 1.2.1 --depth 1 https://github.com/ros-controls/kinematics_interface.git

=======
>>>>>>> 4ee4019 (fix: reduce Dockerfile operations)
RUN sudo mkdir /export && sudo chown ${USER}:${USER} /export
RUN git clone --filter=blob:none --no-checkout -b jazzy https://github.com/ros-perception/image_pipeline.git && \
    cd image_pipeline && \
    git sparse-checkout init --no-cone && \
    echo "camera_calibration/" > .git/info/sparse-checkout && \
    git checkout && mv camera_calibration .. && cd .. && rm -rf image_pipeline && \
    find ./camera_calibration/src/camera_calibration/calibrator.py -type f -exec sed -i 's|/tmp/calibrationdata.tar.gz|/export/calibrationdata.tar.gz|g' {} \;

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

FROM environment-variables AS final
COPY --from=ros2-ws / /
RUN rm -rf /home/ubuntu

# start as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}

RUN echo '#!/bin/bash\n\
    set -e\n\
    source /opt/ros/jazzy/setup.bash\n\
    source /home/ros2/ros2_ws/install/setup.bash\n\
    exec "$@"' > ${HOME}/ros_entrypoint.sh &&  chmod +x ${HOME}/ros_entrypoint.sh

ENTRYPOINT ["/home/ros2/ros_entrypoint.sh"]
CMD ["/usr/local/bin/camera_calibration"]

# Metadata
ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=iron
ARG VERSION=v0.0.0
LABEL org.opencontainers.image.title="AICA camera calibration"
LABEL org.opencontainers.image.description="AICA base camera calibration"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"base/ws","base":{"name":"'${BASE_IMAGE}':'${BASE_TAG}'","version":"'${VERSION}'"}}'
LABEL devcontainer.metadata='[{"containerUser": "ros2"}]'