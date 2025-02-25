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
  && apt-get upgrade -y \
  && rm -rf /var/lib/apt/lists/*

RUN echo "Set disable_coredump false" >> /etc/sudo.conf

# configure sshd server settings
RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PubkeyAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_development \
  && mkdir /run/sshd

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

RUN apt-get update && apt-get install --no-install-recommends -y \
  ros-humble-ros2-control \
  ros-humble-ros2-controllers \
  && rm -rf /var/lib/apt/lists/*


ENV RELEASE=r36.3

RUN apt-get update && apt-get upgrade -y && apt-get install -qq -y --no-install-recommends     bc     bzip2     can-utils     ca-certificates     freeglut3-dev     gnupg2     gstreamer1.0-alsa     gstreamer1.0-libav     gstreamer1.0-plugins-bad     gstreamer1.0-plugins-base     gstreamer1.0-plugins-good     gstreamer1.0-plugins-ugly     gstreamer1.0-tools     i2c-tools     iw     kbd     kmod     language-pack-en-base     libapt-pkg-dev     libcanberra-gtk3-module     libgles2     libglu1-mesa-dev     libglvnd-dev     libgtk-3-0     libpython2.7     libudev1     libvulkan1     libzmq5     mtd-utils     parted     pciutils     python3     python3-pexpect     python3-distutils     python3-numpy     sox     udev     vulkan-tools     wget     wireless-tools wpasupplicant

RUN wget https://repo.download.nvidia.com/jetson/jetson-ota-public.asc -O /tmp/jetson-ota-public.asc
RUN apt-key add /tmp/jetson-ota-public.asc
RUN echo "deb https://repo.download.nvidia.com/jetson/common $RELEASE main" >> /etc/apt/sources.list

RUN echo "/usr/lib/aarch64-linux-gnu/tegra" >> /etc/ld.so.conf.d/nvidia-tegra.conf &&     echo "/usr/lib/aarch64-linux-gnu/tegra-egl" >> /etc/ld.so.conf.d/nvidia-tegra.conf

RUN rm /usr/share/glvnd/egl_vendor.d/50_mesa.json
RUN mkdir -p /usr/share/glvnd/egl_vendor.d/ && echo '{    "file_format_version" : "1.0.0",    "ICD" : {        "library_path" : "libEGL_nvidia.so.0"    }}' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
RUN mkdir -p /usr/share/egl/egl_external_platform.d/ && echo '{    "file_format_version" : "1.0.0",    "ICD" : {        "library_path" : "libnvidia-egl-wayland.so.1"    }}' > /usr/share/egl/egl_external_platform.d/nvidia_wayland.json

RUN ldconfig

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVARCH=arm64
ENV NVIDIA_REQUIRE_CUDA=cuda>=12.2
ENV NV_CUDA_CUDART_VERSION=12.2.140-1
ENV NVIDIA_REQUIRE_JETPACK_HOST_MOUNTS=base-only
ENV CUDA_VERSION=12.2.12

RUN apt-get update && apt-get install -y --no-install-recommends     cuda-cudart-12-2=${NV_CUDA_CUDART_VERSION}     ${NV_CUDA_COMPAT_PACKAGE}
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf     && echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib:$LD_LIBRARY_PATH
ENV NV_LIBCUBLAS_PACKAGE=libcublas-12-2=12.2.5.6-1
ENV NV_LIBCUBLAS_VERSION=12.2.5.6-1
ENV NV_LIBCUBLAS_PACKAGE_NAME=libcublas-12-2
ENV NV_LIBCUSPARSE_VERSION=12.1.2.141-1
ENV NV_LIBNPP_PACKAGE=libnpp-12-2=12.2.1.4-1
ENV NV_LIBNPP_VERSION=12.2.1.4-1
ENV NV_NVTX_VERSION=12.2.140-1
ENV NV_CUDA_LIB_VERSION=12.2.12-1
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_VISIBLE_DEVICES=all

RUN apt-get update && apt-get install -y --no-install-recommends     cuda-libraries-12-2=${NV_CUDA_LIB_VERSION}     ${NV_LIBNPP_PACKAGE}     cuda-nvtx-12-2=${NV_NVTX_VERSION}     libcusparse-12-2=${NV_LIBCUSPARSE_VERSION}     ${NV_LIBCUBLAS_PACKAGE}
RUN apt-mark hold ${NV_LIBCUBLAS_PACKAGE_NAME}

ENV NVIDIA_PRODUCT_NAME=CUDA
ENV NV_LIBCUBLAS_DEV_PACKAGE=libcublas-dev-12-2=12.2.5.6-1
ENV NV_LIBCUBLAS_DEV_VERSION=12.2.5.6-1
ENV NV_LIBCUBLAS_DEV_PACKAGE_NAME=libcublas-dev-12-2
ENV NV_LIBNPP_DEV_PACKAGE=libnpp-dev-12-2=12.2.1.4-1
ENV NV_LIBNPP_DEV_VERSION=12.2.1.4-1
ENV NV_LIBCUSPARSE_DEV_VERSION=12.1.2.141-1
ENV NV_NVML_DEV_VERSION=12.2.140-1
ENV NV_CUDA_CUDART_DEV_VERSION=12.2.140-1
ENV NV_CUDA_LIB_VERSION=12.2.12-1

RUN apt-get update && apt-get install -y --no-install-recommends     cuda-cudart-dev-12-2=${NV_CUDA_CUDART_DEV_VERSION}     cuda-command-line-tools-12-2=${NV_CUDA_LIB_VERSION}     cuda-minimal-build-12-2=${NV_CUDA_LIB_VERSION}     cuda-libraries-dev-12-2=${NV_CUDA_LIB_VERSION}     cuda-nvml-dev-12-2=${NV_NVML_DEV_VERSION}     ${NV_LIBNPP_DEV_PACKAGE}     libcusparse-dev-12-2=${NV_LIBCUSPARSE_DEV_VERSION}     ${NV_LIBCUBLAS_DEV_PACKAGE}
RUN apt-mark hold ${NV_LIBCUBLAS_DEV_PACKAGE_NAME}

ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:$LD_LIBRARY_PATH

# Add Isaac apt repository
RUN wget -qO - https://isaac.download.nvidia.com/isaac-ros/repos.key | apt-key add - && \
    grep -qxF "deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) legacy-release-3.1" /etc/apt/sources.list || \
    echo "deb https://isaac.download.nvidia.com/isaac-ros/release-3 $(lsb_release -cs) legacy-release-3.1" | tee -a /etc/apt/sources.list \
    && apt-get update

# Setup Jetson debian repositories
RUN apt-key adv --fetch-keys https://repo.download.nvidia.com/jetson/jetson-ota-public.asc \
    && apt-key adv --fetch-keys http://l4t-repo.nvidia.com/jetson-ota-internal.key \
    && echo 'deb https://repo.download.nvidia.com/jetson/common r36.3 main' > /etc/apt/sources.list.d/nvidia-l4t-apt-source.list \
    && echo 'deb https://repo.download.nvidia.com/jetson/t234 r36.3 main' >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list \
    && apt-get update

RUN apt-get update && apt-get install -y \
    python3-dev \
    python3-distutils \
    python3-flake8 \
    python3-pip \
    python3-pytest-cov \
    python3-venv \
    python3-zmq \
    python3.10 \
    python3.10-venv

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN apt-get update && apt-get install -y \
    ffmpeg \
    gfortran \
    graphicsmagick-libmagick-dev-compat \
    jq \
    kmod \
    lcov \
    libasio-dev \
    libassimp-dev \
    libatlas-base-dev \
    libblas3 \
    libatlas3-base \
    libboost-all-dev \
    libboost-dev \
    libceres-dev \
    libbullet-dev \
    libcunit1-dev \
    libffi7 \
    libfreetype6 \
    libgraphicsmagick++1-dev \
    libhidapi-libusb0 \
    libinput10 \
    libjpeg8 \
    liblapack3 \
    libmnl0 \
    libmnl-dev \
    libncurses5-dev \
    libode-dev \
    libopenblas0 \
    libopencv-dev=4.5.4+dfsg-9ubuntu4 \
    libopenmpi3 \
    libpcap-dev \
    libpcl-dev \
    libsuitesparse-dev \
    libtinyxml2-dev \
    libturbojpeg \
    linuxptp \
    libunwind8 \
    libv4l-0 \
    libx264-dev \
    libxaw7-dev \
    libyaml-cpp-dev \
    llvm-14 \
    nlohmann-json3-dev \
    python3-opencv=4.5.4+dfsg-9ubuntu4 \
    python3-scipy \
    ninja-build

RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-12-2 \
    cuda-libraries-12-2 \
    cuda-nvml-dev-12-2 \
    cuda-sanitizer-12-2 \
    cuda-toolkit-12-2 \
    libcublas-12-2 \
    libcudnn8 \
    libcusparse-12-2 \
    libnpp-12-2

        
# build as ROS user
USER ${USER}
# WORKDIR ${ROS2_WORKSPACE}/src

# RUN git clone -b 3.18.0 --depth 1 https://github.com/ros-controls/ros2_control.git
# RUN git clone -b 3.14.0 --depth 1 https://github.com/ros-controls/ros2_controllers.git
# # get additional interface dependencies manually
# RUN git clone -b 5.0.0 --depth 1 https://github.com/ros-controls/control_msgs.git
# RUN git clone -b 1.0.2 --depth 1 https://github.com/pal-robotics/backward_ros.git
# RUN git clone -b 3.1.2 --depth 1 https://github.com/ros/diagnostics.git
# RUN git clone -b 2.5.0 --depth 1 https://github.com/ros-controls/realtime_tools.git
# RUN git clone -b 1.7.0 --depth 1 https://github.com/ros2/rcl_interfaces.git
# RUN git clone -b 0.11.0 --depth 1 https://github.com/ros2/test_interface_files.git
# RUN git clone -b 1.16.0 --depth 1 https://github.com/ros/angles.git
# RUN git clone -b ros2 --depth 1 https://github.com/ros-drivers/ackermann_msgs.git
# RUN git clone -b 0.3.3 --depth 1 https://github.com/PickNikRobotics/generate_parameter_library.git
# RUN git clone -b 0.2.2 --depth 1 https://github.com/PickNikRobotics/RSL.git
# RUN git clone -b 1.0.2 --depth 1 https://github.com/PickNikRobotics/cpp_polyfills.git
# RUN git clone -b 3.1.0 --depth 1 https://github.com/ros-controls/control_toolbox.git
# RUN git clone -b 0.1.0 --depth 1 https://github.com/ros-controls/kinematics_interface.git

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

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
  libcap-dev \
  python3-jinja2 \
  python3-typeguard \
  && rm -rf /var/lib/apt/lists/*

# build as ROS user
USER ${USER}
WORKDIR ${ROS2_WORKSPACE}/src

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

WORKDIR ${ROS2_WORKSPACE}
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash; colcon build"
RUN rm -rf ./src

FROM ros2-control-${ROS_DISTRO} AS ros2-control

FROM environment-variables AS final
COPY --from=ros2-control / /
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
