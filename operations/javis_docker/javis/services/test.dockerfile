# todo: fix Realsense issues: color image, gyro, accel, point clouds, GPU [done]
# todo: switch to a dusty_nv container https://github.com/dusty-nv/jetson-containers/blob/master/packages/ros/Dockerfile.ros2 or Nvidia ISAAC ROS or Mine
# todo: setup NVIDIA ISAAC NVBLOX (mapping) and map localizer
# Todo: setup Nvidia ISAAC ROS vSLAM
# todo: setup particle filter
# todo: install Autoware dev tools manually since we're not using their container or modify setup-dev-env and ansible scripts [done]
# todo: use a "repos" file and pull with vcs for source files and use an apt list file for apt installation
# todo: add kiss-icp suport https://github.com/PRBonn/kiss-icp
# pull base image. Any base image with CUDA, cuDNN, TensorRT and Pytorch installed. Optionally OpenCV, tensorflow, etc
# Autoware: https://github.com/autowarefoundation/autoware/pkgs/container/autoware-universe/versions?filters%5Bversion_type%5D=tagged
# or OSRF ROS2 or Dusty-NV
#FROM ghcr.io/autowarefoundation/autoware-openadk:latest-humble-devel-cuda
#FROM privvyledge/r36.2.0-ros-humble-ml:latest
FROM nvcr.io/nvidia/l4t-ml:r36.2.0-py3

# Set up the shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV TZ=America/New_York

# Setup user todo
ARG USER=developer
ARG USERNAME=${USER}
ENV USERNAME ${USERNAME}

ARG USER_UID=1000
ARG USER_GID=$USER_UID

#RUN groupadd --gid $USER_GID $USERNAME && \
#        useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
#        echo "$USERNAME:$USERNAME" | chpasswd && \
#        usermod --shell /bin/bash $USERNAME && \
#        usermod -aG sudo,video $USERNAME && \
#        usermod  --uid $USER_UID $USERNAME && \
#        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
#        chmod 0440 /etc/sudoers.d/$USERNAME

RUN groupadd --gid $USER_GID $USERNAME && \
        useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
        echo "$USERNAME:$USERNAME" | chpasswd && \
        usermod --shell /bin/bash $USERNAME && \
        usermod -aG sudo,video $USERNAME && \
        usermod  --uid $USER_UID $USERNAME

# Setup env and shell
ENV LOGNAME root
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV TZ=America/New_York

ARG ROS_VERSION="ROS2"
ARG ROS_DISTRO="humble"
ENV ROS_DISTRO=${ROS_DISTRO}
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

ENV NVIDIA_DRIVER_CAPABILITIES all
ENV NVIDIA_VISIBLE_DEVICES all

# Install Sudo
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -yq sudo tzdata && \
    ln -fns /usr/share/zoneinfo/${TZ} /etc/localtime && echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# ARG user_id=$user_id
# ENV USERNAME developer
# # Commands below run as the developer user
# USER $USERNAME
# When running a container start in the developer's home folder
# WORKDIR /home/$USERNAME

