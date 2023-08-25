ARG BASE_TAG=humble
FROM ros:${BASE_TAG} as environment-variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources
ENV PIP_NO_CACHE_DIR 1
ENV USER ros2
ENV HOME /home/${USER}
ENV ROS2_WORKSPACE /home/${USER}/ros2_ws
ENV COLCON_HOME ${HOME}/.colcon
ENV COLCON_DEFAULTS_FILE ${COLCON_HOME}/defaults.yaml
ENV COLCON_WORKSPACE=${ROS2_WORKSPACE}
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib


FROM environment-variables as base-dependencies

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


FROM base-dependencies as base-workspace

# create and configure a new user
ARG UID=1000
ARG GID=1000
RUN addgroup --gid ${GID} ${USER}
RUN adduser --gecos "ROS2 User" --uid ${UID} --gid ${GID} ${USER} && yes | passwd ${USER}
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
RUN mkdir /root/.ssh/ && ssh-keyscan github.com | tee -a /root/.ssh/known_hosts
RUN echo "session required pam_limits.so" | tee --append /etc/pam.d/common-session > /dev/null


FROM environment-variables as final
COPY --from=base-workspace / /

# start as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}
