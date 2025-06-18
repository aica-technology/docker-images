ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy-ros-core
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ${BASE_IMAGE}:${BASE_TAG} AS environment-variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources
ENV PIP_NO_CACHE_DIR=1
ENV USER=ros2
ENV HOME=/home/${USER}
ENV ROS2_WORKSPACE=/home/${USER}/ros2_ws

FROM environment-variables AS base-dependencies

# disable suggested and recommended install
RUN apt-config dump | grep -we Recommends -e Suggests | sed s/1/0/ \
    > /etc/apt/apt.conf.d/999norecommend

# install base dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    python3-semver \
    python3-rosdep \
    python3-colcon-common-extensions \
    python3-colcon-ros \
    ros-${ROS_DISTRO}-rclpy \
    ros-${ROS_DISTRO}-message-filters \
    ros-${ROS_DISTRO}-image-geometry \
    ros-${ROS_DISTRO}-cv-bridge \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get clean
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

RUN usermod -l ${USER} ubuntu
RUN groupmod -n ${USER} ubuntu
RUN usermod -d ${HOME} -m ros2
RUN chfn -f "ROS2 User" ros2

RUN usermod -a -G dialout ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_aptget
RUN chmod 0440 /etc/sudoers.d/99_aptget && chown root:root /etc/sudoers.d/99_aptget

COPY ./config/sshd_entrypoint.sh /sshd_entrypoint.sh
RUN chmod 744 /sshd_entrypoint.sh

USER ${USER}
WORKDIR ${HOME}
COPY --chown=${USER}:${USER} ./config/camera_calibration.sh /usr/local/bin/camera_calibration

RUN mkdir -p ${ROS2_WORKSPACE}/src
WORKDIR ${ROS2_WORKSPACE}/srcf
RUN sudo rosdep init
RUN rosdep update
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build --symlink-install"

RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash; \
    source ${ROS2_WORKSPACE}/install/setup.bash" >> ${HOME}/.bashrc
RUN echo "export RCUTILS_COLORIZED_OUTPUT=1" >> ${HOME}/.bashrc

# clone sparse camera_calibration
RUN git clone --filter=blob:none --no-checkout -b jazzy https://github.com/ros-perception/image_pipeline.git && \
    cd image_pipeline && \
    git sparse-checkout init --no-cone && \
    echo "camera_calibration/" > .git/info/sparse-checkout && \
    git checkout && mv camera_calibration .. && cd .. && rm -rf image_pipeline && \
    find ./camera_calibration/src/camera_calibration/calibrator.py -type f -exec sed -i 's|/tmp/calibrationdata.tar.gz|/export/calibrationdata.tar.gz|g' {} \;

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

RUN sudo mkdir /export && sudo chown ${USER}:${USER} /export

FROM environment-variables AS final
COPY --from=base-dependencies / /

# start as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}

RUN echo '#!/bin/bash\n\
    set -e\n\
    source /opt/ros/${ROS_DISTRO}/setup.bash\n\
    source ${ROS2_WORKSPACE}/install/setup.bash\n\
    exec "$@"' > ${HOME}/ros_entrypoint.sh && chmod +x ${HOME}/ros_entrypoint.sh

ENTRYPOINT ["/home/ros2/ros_entrypoint.sh"]
CMD ["/usr/local/bin/camera_calibration"]

# Metadata
ARG BASE_IMAGE
ARG BASE_TAG
ARG VERSION
LABEL org.opencontainers.image.title="AICA camera calibration"
LABEL org.opencontainers.image.description="AICA base camera calibration"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"base/camera-calibration","base":{"name":"'${BASE_IMAGE}':'${BASE_TAG}'","version":"'${VERSION}'"}}'
LABEL devcontainer.metadata='[{"containerUser": "ros2"}]'