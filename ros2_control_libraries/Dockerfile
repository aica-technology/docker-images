ARG BASE_IMAGE=ghcr.io/eeberhard/ros2-ws
ARG BASE_TAG=galactic
FROM ${BASE_IMAGE}:${BASE_TAG}

# install google dependencies
COPY --from=ghcr.io/eeberhard/control-libraries/proto-dependencies:latest /usr/local/include/google /usr/local/include/google
COPY --from=ghcr.io/eeberhard/control-libraries/proto-dependencies:latest /usr/local/lib/libproto* /usr/local/lib/
COPY --from=ghcr.io/eeberhard/control-libraries/proto-dependencies:latest /usr/local/bin/protoc /usr/local/bin
RUN sudo ldconfig

ARG CL_BRANCH=main
WORKDIR ${HOME}
RUN git clone -b ${CL_BRANCH} --depth 1 https://github.com/epfl-lasa/control-libraries.git

# install source
RUN sudo ./control-libraries/source/install.sh -y
ENV CMAKE_PREFIX_PATH=/opt/openrobots:${CMAKE_PREFIX_PATH}
# install protocol
RUN sudo ./control-libraries/protocol/install.sh -y
# install python bindings
RUN sudo pip3 install ./control-libraries/python
RUN sudo rm -rf ./control-libraries

RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# Restore the key for robotpkg
RUN sudo curl http://robotpkg.openrobots.org/packages/debian/robotpkg.key | sudo apt-key add -
