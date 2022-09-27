ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-ws
ARG BASE_TAG=galactic
ARG UBUNTU_VERSION=focal-fossa
FROM ${BASE_IMAGE}:${BASE_TAG} as jammy-jellyfish

# install development dependencies
COPY --from=ghcr.io/epfl-lasa/control-libraries/development-dependencies:22.04 /usr/local /tmp/local
RUN sudo cp -R /tmp/local/* /usr/local && sudo rm -r /tmp/local


FROM ${BASE_IMAGE}:${BASE_TAG} as focal-fossa

# install development dependencies
COPY --from=ghcr.io/epfl-lasa/control-libraries/development-dependencies:20.04 /usr/local /tmp/local
RUN sudo cp -R /tmp/local/* /usr/local && sudo rm -r /tmp/local


FROM ${UBUNTU_VERSION}
WORKDIR ${HOME}

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
