ARG ROS_DISTRO=noetic
FROM ros:${ROS_DISTRO} as base-dependencies
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  build-essential \
  curl \
  g++ \
  gdb \
  git \
  iputils-ping \
  libboost-all-dev \
  libeigen3-dev \
  libtool \
  libssl-dev \
  make \
  mesa-utils \
  nano \
  python3-setuptools \
  python3-pip \
  python3-rosdep \
  python3-rosinstall \
  python3-rosinstall-generator \
  python3-wstool \
  ros-${ROS_DISTRO}-rviz \
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
ENV USER ros
ENV HOME /home/${USER}

# create and configure a new user
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
RUN mkdir -p ${HOME}/ros_ws/src
WORKDIR ${HOME}/ros_ws/
RUN rosdep update
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; catkin_make"

# set up environment
USER root

# prepend the environment sourcing to bashrc (appending will fail for non-interactive sessions)
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash; \
source /home/${USER}/ros_ws/devel/setup.bash" | cat - ${HOME}/.bashrc > tmp && mv tmp ${HOME}/.bashrc
RUN echo "session required pam_limits.so" | sudo tee --append /etc/pam.d/common-session > /dev/null

WORKDIR ${HOME}/ros_ws

# Clean image
RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# start as the user on default login unless the CMD is overridden.
CMD su --login ${USER}
