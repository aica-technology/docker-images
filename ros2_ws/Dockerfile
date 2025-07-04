ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=jazzy
ARG ROS_DISTRO=jazzy
ARG VERSION=v0.0.0

FROM ${BASE_IMAGE}:${BASE_TAG} AS environment-variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources
ENV PIP_NO_CACHE_DIR=1
ENV USER=ros2
ENV HOME=/home/${USER}
ENV ROS2_WORKSPACE=/home/${USER}/ros2_ws
ENV COLCON_HOME=${HOME}/.colcon
ENV COLCON_DEFAULTS_FILE=${COLCON_HOME}/defaults.yaml
ENV COLCON_WORKSPACE=${ROS2_WORKSPACE}


FROM environment-variables AS base-dependencies

# disable suggested and recommended install
RUN apt-config dump | grep -we Recommends -e Suggests | sed s/1/0/ \
  | sudo tee /etc/apt/apt.conf.d/999norecommend

# install base dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  autoconf \
  automake \
  curl \
  featherpad \
  gdb \
  git \
  iputils-ping \
  libboost-all-dev \
  libtool \
  mesa-utils \
  nano \
  python3-pip \
  ros-${ROS_DISTRO}-xacro \
  ros-${ROS_DISTRO}-robot-state-publisher \
  ros-${ROS_DISTRO}-rviz2 \
  rsync \
  software-properties-common \
  ssh \
  unzip \
  wget \
  && rm -rf /var/lib/apt/lists/*

RUN echo "Set disable_coredump false" >> /etc/sudo.conf

# configure sshd server settings
RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PubkeyAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_development \
  && mkdir /run/sshd

FROM base-dependencies AS build-go
ARG TARGETPLATFORM
ARG GOVERSION=1.24.2

RUN wget https://go.dev/dl/go${GOVERSION}.linux-${TARGETPLATFORM#*/}.tar.gz -O /tmp/go.tar.gz && \
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz && \
  rm /tmp/go.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin"
WORKDIR /go
COPY config/validate_json ./
RUN --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/go/pkg/mod \
  go build

FROM base-dependencies AS base-user-humble

# create and configure a new user
RUN addgroup --gid 1000 ${USER}
RUN adduser --gecos "ROS2 User" --uid 1000 --gid 1000 ${USER} && yes | passwd ${USER}

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

# configure sshd entrypoint to authorise the new user for ssh access and
# optionally update UID and GID when invoking the container with the entrypoint script
COPY ./config/sshd_entrypoint.sh /sshd_entrypoint.sh
RUN chmod 744 /sshd_entrypoint.sh

# crete user group with realtime permissions and add user to it
RUN groupadd -g 3719 realtime && usermod -aG realtime ${USER}
RUN echo "@realtime        soft    rtprio          99\n@realtime        hard    rtprio          99\n" > \
    /etc/security/limits.d/realtime.conf

# configure colcon defaults and utilities
USER ${USER}
WORKDIR ${HOME}
RUN wget https://raw.githubusercontent.com/aica-technology/.github/v0.9.0/guidelines/.clang-format
COPY ./config/config.rviz config.rviz
COPY --chown=${USER}:${USER} ./config/generate_compile_commands.sh /usr/local/bin/generate_compile_commands
COPY --chown=${USER}:${USER} ./config/InstallAicaDescriptions.cmake /tmp
RUN sudo mv /tmp/InstallAicaDescriptions.cmake /usr/share/cmake-$(cmake --version | awk '/cmake version/ {split($3, v, "."); print v[1]"."v[2]}')/Modules
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

# create the credentials to be able to pull private repos using ssh
USER root
RUN mkdir -p /root/.ssh/ && ssh-keyscan github.com | tee -a /root/.ssh/known_hosts
RUN echo "session required pam_limits.so" | tee --append /etc/pam.d/common-session > /dev/null

FROM base-workspace AS ros2-control-humble

# build as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

RUN sudo apt-get update && sudo apt-get install --no-install-recommends -y \
  libcap-dev \
  && sudo rm -rf /var/lib/apt/lists/*

FROM base-workspace AS ros2-control-iron

RUN apt-get update && apt-get install --no-install-recommends -y \
  doxygen \
  librange-v3-dev \
  python3-jinja2 \
  python3-typeguard \
  && rm -rf /var/lib/apt/lists/*

# build as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}/src

RUN git clone -b 3.18.0 --depth 1 https://github.com/ros-controls/ros2_control.git
RUN git clone -b 3.14.0 --depth 1 https://github.com/ros-controls/ros2_controllers.git
# get additional interface dependencies manually
RUN git clone -b 5.0.0 --depth 1 https://github.com/ros-controls/control_msgs.git
RUN git clone -b 1.0.2 --depth 1 https://github.com/pal-robotics/backward_ros.git
RUN git clone -b 3.1.2 --depth 1 https://github.com/ros/diagnostics.git
RUN git clone -b 2.5.0 --depth 1 https://github.com/ros-controls/realtime_tools.git
RUN git clone -b 1.7.0 --depth 1 https://github.com/ros2/rcl_interfaces.git
RUN git clone -b 0.11.0 --depth 1 https://github.com/ros2/test_interface_files.git
RUN git clone -b 1.16.0 --depth 1 https://github.com/ros/angles.git
RUN git clone -b ros2 --depth 1 https://github.com/ros-drivers/ackermann_msgs.git
RUN git clone -b 0.3.3 --depth 1 https://github.com/PickNikRobotics/generate_parameter_library.git
RUN git clone -b 0.2.2 --depth 1 https://github.com/PickNikRobotics/RSL.git
RUN git clone -b 1.0.2 --depth 1 https://github.com/PickNikRobotics/cpp_polyfills.git
RUN git clone -b 3.1.0 --depth 1 https://github.com/ros-controls/control_toolbox.git
RUN git clone -b 0.1.0 --depth 1 https://github.com/ros-controls/kinematics_interface.git

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

FROM base-workspace AS ros2-control-jazzy
RUN apt-get update && apt-get install --no-install-recommends -y \
  # doxygen \
  # librange-v3-dev \
  python3-jinja2 \
  python3-typeguard \
  && rm -rf /var/lib/apt/lists/*

# build as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}/src

RUN git clone -b 4.17.0 --depth 1 https://github.com/ros-controls/ros2_control.git
RUN git clone -b 4.14.0 --depth 1 https://github.com/ros-controls/ros2_controllers.git
# get additional interface dependencies manually
RUN git clone -b 5.2.0 --depth 1 https://github.com/ros-controls/control_msgs.git
RUN git clone -b 1.0.3 --depth 1 https://github.com/pal-robotics/backward_ros.git
RUN git clone -b 4.3.1 --depth 1 https://github.com/ros/diagnostics.git
RUN git clone -b 2.6.0 --depth 1 https://github.com/ros-controls/realtime_tools.git
RUN git clone -b 2.2.0 --depth 1 https://github.com/ros2/rcl_interfaces.git
RUN git clone -b 0.12.0 --depth 1 https://github.com/ros2/test_interface_files.git
RUN git clone -b 1.16.0 --depth 1 https://github.com/ros/angles.git
RUN git clone -b ros2 --depth 1 https://github.com/ros-drivers/ackermann_msgs.git
RUN git clone -b 0.3.8 --depth 1 https://github.com/PickNikRobotics/generate_parameter_library.git
RUN git clone -b 1.1.0 --depth 1 https://github.com/PickNikRobotics/RSL.git
RUN git clone -b 1.0.2 --depth 1 https://github.com/PickNikRobotics/cpp_polyfills.git
RUN git clone -b 3.2.0 --depth 1 https://github.com/ros-controls/control_toolbox.git
RUN git clone -b 2.1.2 --depth 1 https://github.com/ros/filters.git
RUN git clone -b 1.1.0 --depth 1 https://github.com/ros-controls/kinematics_interface.git

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

FROM ros2-control-${ROS_DISTRO} AS ros2-control

FROM environment-variables AS final
COPY --from=ros2-control / /
COPY --from=build-go /go/validate_json /usr/bin/
RUN rm -rf /home/ubuntu

# start as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}

# Metadata
ARG BASE_IMAGE=docker.io/library/ros
ARG BASE_TAG=iron
ARG VERSION=v0.0.0
LABEL org.opencontainers.image.title="AICA ROS 2 image"
LABEL org.opencontainers.image.description="AICA base ROS 2 image (includes ros2_control)"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"
LABEL tech.aica.image.metadata='{"type":"base/ws","base":{"name":"'${BASE_IMAGE}':'${BASE_TAG}'","version":"'${VERSION}'"}}'
LABEL devcontainer.metadata='[{"containerUser": "ros2"}]'