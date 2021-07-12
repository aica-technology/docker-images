ARG ROS_DISTRO=foxy
FROM ros:${ROS_DISTRO} as base-dependencies
ENV DEBIAN_FRONTEND=noninteractive

COPY config/apt-key /tmp/apt-key
RUN apt-key add /tmp/apt-key

RUN apt update && apt install -y \
  autoconf \
  automake \
  build-essential \
  curl \
  g++ \
  gdb \
  iputils-ping \
  libboost-all-dev \
  libeigen3-dev \
  libtool \
  libssl-dev \
  make \
  mesa-utils \
  python3-setuptools \
  python3-pip \
  ros-${ROS_DISTRO}-rviz2 \
  rsync \
  software-properties-common \
  ssh \
  sudo \
  unzip \
  && rm -rf /var/lib/apt/lists/*

RUN echo "Set disable_coredump false" >> /etc/sudo.conf

# Configure sshd server settings
RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PubkeyAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_development \
  && mkdir /run/sshd


FROM base-dependencies as base-workspace
ENV USER ros2
ENV HOME /home/${USER}

# create amd configure a new user
ARG UID=1000
ARG GID=1000
RUN addgroup --gid ${GID} ${USER}
RUN adduser --gecos "ROS User" --uid ${UID} --gid ${GID} ${USER} && yes | passwd ${USER}
RUN usermod -a -G dialout ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_aptget
RUN chmod 0440 /etc/sudoers.d/99_aptget && chown root:root /etc/sudoers.d/99_aptget

# Configure sshd entrypoint to authorise the new user for ssh access and
# optionally update UID and GID when invoking the container with the entrypoint script
COPY ./config/sshd_entrypoint.sh /sshd_entrypoint.sh
RUN chmod 744 /sshd_entrypoint.sh

# build ROS workspace
USER ${USER}
WORKDIR ${HOME}/ros2_ws/
RUN mkdir -p src
RUN rosdep update
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build --symlink-install"

# set up environment
USER root

# prepend the environment sourcing to bashrc (appending will fail for non-interactive sessions)
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash; \
source /home/${USER}/ros2_ws/install/setup.bash" | cat - ${HOME}/.bashrc > tmp && mv tmp ${HOME}/.bashrc
RUN echo "session required pam_limits.so" | sudo tee --append /etc/pam.d/common-session > /dev/null

WORKDIR ${HOME}/ros2_ws

# Clean image
RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# start as the user on default login unless the CMD is overridden.
CMD su --login ${USER}
