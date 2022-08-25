#!/bin/bash

# enable the colcon_cd utility
echo 'source /usr/share/colcon_cd/function/colcon_cd.sh; export _colcon_cd_root="${COLCON_WORKSPACE}"' >> ~/.bashrc

# add aliases
echo "alias cb='export ROS2_WORKSPACE; /bin/bash ${COLCON_HOME}/build.sh'" >> "${HOME}"/.bash_aliases
echo "alias ct='export ROS2_WORKSPACE; /bin/bash ${COLCON_HOME}/test.sh'" >> "${HOME}"/.bash_aliases
echo "alias ccd=colcon_cd" >> "${HOME}"/.bash_aliases
