ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-ws
ARG ROS_VERSION=foxy
FROM ${BASE_IMAGE}:${ROS_VERSION}

# install google dependencies
COPY --from=ghcr.io/epfl-lasa/control-libraries/development-dependencies:latest /usr/local/include/google /usr/local/include/google
COPY --from=ghcr.io/epfl-lasa/control-libraries/development-dependencies:latest /usr/local/lib/libproto* /usr/local/lib/
COPY --from=ghcr.io/epfl-lasa/control-libraries/development-dependencies:latest /usr/local/bin/protoc /usr/local/bin
RUN sudo ldconfig

ARG CL_BRANCH=main
WORKDIR ${HOME}
RUN git clone -b ${CL_BRANCH} --single-branch https://github.com/epfl-lasa/control-libraries.git

# install source
RUN sudo ./control-libraries/source/install.sh -y
# install protocol
RUN sudo ./control-libraries/protocol/install.sh -y
# install python bindings
RUN sudo pip3 install ./control-libraries/python
# remove files except protocol
RUN mv ./control-libraries/protocol ./protocol && rm -rf ./control-libraries/* && mv ./protocol ./control-libraries/protocol

RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*
