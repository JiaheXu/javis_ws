# //////////////////////////////////////////////////////////////////////////////
# javis siimulation dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

# //////////////////////////////////////////////////////////////////////////////
# ros install
RUN sudo /bin/sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
 && sudo /bin/sh -c 'apt-key adv --keyserver  hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' \
 && sudo /bin/sh -c 'apt-key adv --keyserver keys.gnupg.net --recv-key C8B3A55A6F3EFCDE || apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C8B3A55A6F3EFCDE' \
 && sudo apt-get update \
 && sudo apt-get remove -y ros-noetic-velodyne-gazebo* \
 && sudo apt-get install -y --no-install-recommends \
  ros-noetic-ackermann* \
  ros-noetic-ros-controllers \
  ros-noetic-ros-control \
 && sudo apt-get clean \
 && sudo rm -rf /var/lib/apt/lists/*
RUN rosdep update

# //////////////////////////////////////////////////////////////////////////////
# javis workspace deps.
# RUN pip install wheel --user
# RUN pip install wheel setuptools PyYAML pexpect tmuxp pyquaternion --user
# python3 deps
# RUN sudo -H pip3 install rosdep rospkg rosinstall_generator rosinstall wstool vcstools catkin_tools catkin_pkg

# export PYTHON paths
# ENV PYTHONPATH="/home/${USERNAME}/.local/lib/python2.7/site-packages/:${PYTHONPATH}"
# ENV PATH="/home/${USERNAME}/.local/bin/:${PATH}"

# //////////////////////////////////////////////////////////////////////////////
# entrypoint startup

# entrypoint env vars
# ARG arch=$arch
# ENV entrypoint_container_path /docker-entrypoint/

# add entrypoint scripts (general & system specific)
# ADD entrypoints/ $entrypoint_container_path/
#ADD $arch/entrypoints/ $entrypoint_container_path/

# execute entrypoint script
# RUN sudo chmod +x -R $entrypoint_container_path/
# set image to run entrypoint script
# ENTRYPOINT $entrypoint_container_path/docker-entrypoint.bash

RUN sudo apt-get remove libprotobuf-dev protobuf-compiler -y
RUN sudo rm -rf /usr/local/bin/protoc /usr/bin/protoc /usr/local/include/google /usr/local/include/protobuf* /usr/include/google /usr/include/protobuf* \
 && sudo apt update \
 && sudo apt install libusb-dev ros-noetic-gazebo-ros-pkgs ros-noetic-gazebo-ros-control -y \
 && sudo cp -r /usr/include/google/ /usr/local/include
