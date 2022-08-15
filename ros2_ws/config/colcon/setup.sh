#!/bin/bash

# enable the colcon_cd utility
echo "source /usr/share/colcon_cd/function/colcon_cd.sh; export _colcon_cd_root=${ROS2_WORKSPACE}" >> ~/.bashrc

# add aliases
echo "alias cb='bash ${COLCON_HOME}/build.sh'" >> "${HOME}"/.bash_aliases
echo "alias ct='bash ${COLCON_HOME}/test.sh'" >> "${HOME}"/.bash_aliases
echo "alias ccd=colcon_cd" >> "${HOME}"/.bash_aliases
