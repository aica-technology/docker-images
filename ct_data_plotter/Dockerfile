ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy-ros-core
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ${BASE_IMAGE}:${BASE_TAG} AS environment-variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_NO_CACHE_DIR=1
ENV USER=ros2
ENV HOME=/home/${USER}

FROM environment-variables AS base-dependencies

# disable suggested and recommended install
RUN apt-config dump | grep -we Recommends -e Suggests | sed s/1/0/ \
    > /etc/apt/apt.conf.d/999norecommend

RUN apt-get update && apt-get install --no-install-recommends -y \
    sudo \
    python3-pip \
    python3-tk \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get clean

RUN usermod -l ${USER} ubuntu
RUN groupmod -n ${USER} ubuntu
RUN usermod -d ${HOME} -m ros2
RUN chfn -f "ROS2 User" ros2

RUN usermod -a -G dialout ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_aptget
RUN chmod 0440 /etc/sudoers.d/99_aptget && chown root:root /etc/sudoers.d/99_aptget

RUN pip3 install --break-system-packages \
    matplotlib \
    mcap \
    mcap-ros2-support

USER ${USER}
WORKDIR ${HOME}

COPY --chown=${USER}:${USER} ./config/plot.py /usr/local/bin/plot.py
RUN chmod +x /usr/local/bin/plot.py

FROM environment-variables AS final
COPY --from=base-dependencies / /

USER ${USER}
WORKDIR ${HOME}

RUN echo '#!/bin/bash\n\
set -e\n\
source /opt/ros/${ROS_DISTRO}/setup.bash\n\
exec "$@"' > ${HOME}/ros_entrypoint.sh && chmod +x ${HOME}/ros_entrypoint.sh

ENTRYPOINT ["/home/ros2/ros_entrypoint.sh"]
CMD ["python3", "/usr/local/bin/plot.py", "/bag", "--save", "/export/plot.png"]

# Metadata
ARG BASE_IMAGE
ARG BASE_TAG
ARG VERSION
LABEL org.opencontainers.image.title="AICA CT data plotter"
LABEL org.opencontainers.image.description="Plots cartesian trajectory data from ROS 2 bags"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"
LABEL devcontainer.metadata='[{"containerUser": "ros2"}]'
