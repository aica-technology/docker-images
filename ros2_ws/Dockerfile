ARG ROS_VERSION=galactic
FROM ros:${ROS_VERSION} as base-dependencies
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  build-essential \
  curl \
  featherpad \
  gdb \
  git \
  iputils-ping \
  libboost-all-dev \
  libbz2-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libtool \
  llvm \
  make \
  mesa-utils \
  nano \
  ros-${ROS_DISTRO}-xacro \
  ros-${ROS_DISTRO}-robot-state-publisher \
  ros-${ROS_DISTRO}-rviz2 \
  rsync \
  software-properties-common \
  ssh \
  tk-dev \
  unzip \
  wget \
  xz-utils \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN echo "Set disable_coredump false" >> /etc/sudo.conf

# Configure sshd server settings
RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PubkeyAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_development \
  && mkdir /run/sshd


FROM base-dependencies as python3-install
ARG PYTHON_VER=3.10.2
WORKDIR /tmp

RUN wget https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tar.xz
RUN tar -xf Python-${PYTHON_VER}.tar.xz
WORKDIR Python-${PYTHON_VER}
RUN ./configure --enable-optimizations --with-ensurepip=install \
  && make -j8 \
  && make install
RUN ldconfig

RUN python3 -m pip install --upgrade pip catkin_pkg empy numpy lark


FROM python3-install as base-workspace
ENV USER ros2
ENV HOME /home/${USER}
ENV ROS2_WORKSPACE /home/${USER}/ros2_ws

# create amd configure a new user
ARG UID=1000
ARG GID=1000
RUN addgroup --gid ${GID} ${USER}
RUN adduser --gecos "ROS2 User" --uid ${UID} --gid ${GID} ${USER} && yes | passwd ${USER}
RUN usermod -a -G dialout ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_aptget
RUN chmod 0440 /etc/sudoers.d/99_aptget && chown root:root /etc/sudoers.d/99_aptget

# Configure sshd entrypoint to authorise the new user for ssh access and
# optionally update UID and GID when invoking the container with the entrypoint script
COPY ./config/sshd_entrypoint.sh /sshd_entrypoint.sh
RUN chmod 744 /sshd_entrypoint.sh

# build ROS workspace
USER ${USER}
RUN mkdir -p ${ROS2_WORKSPACE}/src
WORKDIR ${ROS2_WORKSPACE}
RUN rosdep update
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build --symlink-install"

# create the credentials to be able to pull private repos using ssh
USER root
RUN mkdir /root/.ssh/ && ssh-keyscan github.com | tee -a /root/.ssh/known_hosts

# prepend the environment sourcing to bashrc (appending will fail for non-interactive sessions)
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash; \
source ${ROS2_WORKSPACE}/install/setup.bash" | cat - ${HOME}/.bashrc > tmp && mv tmp ${HOME}/.bashrc
RUN echo "session required pam_limits.so" | tee --append /etc/pam.d/common-session > /dev/null

# start as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}

# Clean image
RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && sudo rm -rf /tmp/*
