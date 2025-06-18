ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy-ros-core
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ${BASE_IMAGE}:${BASE_TAG} AS environment-variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS2_WORKSPACE=/ws
ENV UID=1000
ENV GID=1000

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
    ros-${ROS_DISTRO}-image-geometry \
    ros-${ROS_DISTRO}-cv-bridge \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get clean

COPY --chown=${UID}:${GID} ./scripts/camera_calibration.sh /usr/local/bin/camera_calibration

RUN mkdir -p ${ROS2_WORKSPACE}/src
WORKDIR ${ROS2_WORKSPACE}
RUN rosdep init
RUN rosdep update
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build --symlink-install"

RUN git clone --filter=blob:none --no-checkout -b jazzy https://github.com/ros-perception/image_pipeline.git && \
    cd image_pipeline && \
    git sparse-checkout init --no-cone && \
    echo "camera_calibration/" > .git/info/sparse-checkout && \
    git checkout && mv camera_calibration .. && cd .. && rm -rf image_pipeline && \
    find ./camera_calibration/src/camera_calibration/calibrator.py -type f -exec sed -i 's|/tmp/calibrationdata.tar.gz|/export/calibrationdata.tar.gz|g' {} \;

RUN mkdir /export && chown ${UID}:${GID} /export

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

FROM environment-variables AS final
COPY --from=base-dependencies / /
RUN rm -rf /home/ubuntu

# start as ROS user
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
ARG BASE_TAG=jazzy
ARG VERSION=v0.0.0
LABEL org.opencontainers.image.title="AICA camera calibration"
LABEL org.opencontainers.image.description="AICA base camera calibration"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"base/ws","base":{"name":"'${BASE_IMAGE}':'${BASE_TAG}'","version":"'${VERSION}'"}}'
LABEL devcontainer.metadata='[{"containerUser": "ros2"}]'