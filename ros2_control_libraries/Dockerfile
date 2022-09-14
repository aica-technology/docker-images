ARG BASE_IMAGE=ghcr.io/eeberhard/ros2-ws
ARG BASE_TAG=galactic
FROM ${BASE_IMAGE}:${BASE_TAG}
WORKDIR ${HOME}

# install development dependencies
COPY --from=ghcr.io/epfl-lasa/control-libraries/development-dependencies:latest /usr/local /tmp/local
RUN sudo cp -R /tmp/local/* /usr/local && sudo rm -r /tmp/local

RUN sudo ldconfig

ARG CL_BRANCH=main
RUN git clone -b ${CL_BRANCH} --depth 1 https://github.com/epfl-lasa/control-libraries.git

# install source
RUN sudo ./control-libraries/source/install.sh -y

# install protocol
RUN sudo ./control-libraries/protocol/install.sh -y

# install python bindings
RUN sudo pip3 install ./control-libraries/python
RUN sudo rm -rf ./control-libraries

RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*
