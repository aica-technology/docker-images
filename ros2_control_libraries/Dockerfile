ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-control
ARG BASE_TAG=humble
ARG UBUNTU_VERSION=jammy-jellyfish
FROM ${BASE_IMAGE}:${BASE_TAG} as jammy-jellyfish

# install development dependencies and copy licenses
COPY --from=ghcr.io/aica-technology/control-libraries/development-dependencies:22.04 /usr/local /tmp/local
RUN sudo cp -R /tmp/local/* /usr/local && sudo rm -r /tmp/local
COPY --from=ghcr.io/aica-technology/control-libraries/development-dependencies:22.04 \
  /usr/share/doc/control-libraries/licenses /usr/share/doc/control-libraries/licenses


FROM ${BASE_IMAGE}:${BASE_TAG} as focal-fossa

# install development dependencies and copy licenses
COPY --from=ghcr.io/aica-technology/control-libraries/development-dependencies:20.04 /usr/local /tmp/local
RUN sudo cp -R /tmp/local/* /usr/local && sudo rm -r /tmp/local
COPY --from=ghcr.io/aica-technology/control-libraries/development-dependencies:20.04 \
  /usr/share/doc/control-libraries/licenses /usr/share/doc/control-libraries/licenses


FROM ${UBUNTU_VERSION} as control-libraries-build
WORKDIR /tmp

RUN sudo ldconfig

ARG CL_BRANCH=main
RUN git clone -b ${CL_BRANCH} --depth 1 https://github.com/aica-technology/control-libraries.git

# install source
RUN sudo ./control-libraries/source/install.sh -y

# install protocol
RUN sudo ./control-libraries/protocol/install.sh -y

# install python bindings
RUN sudo pip3 install ./control-libraries/python

# clean image
RUN sudo rm -rf /tmp/* && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

FROM ${BASE_IMAGE}:${BASE_TAG} as final
RUN sudo rm -rf /usr/include/eigen3
COPY --from=control-libraries-build /usr/ /usr/
RUN sudo ldconfig