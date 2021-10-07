ARG BASE_IMAGE=ghcr.io/aica-technology/ros2-modulo
ARG ROS_VERSION=foxy
FROM ${BASE_IMAGE}:${ROS_VERSION}

RUN sudo apt-get update && sudo apt-get install -y \
  ros-${ROS_VERSION}-ros2-control \
  ros-${ROS_VERSION}-ros2-controllers \
  && sudo ldconfig \
  && sudo rm -rf /var/lib/apt/lists/*
