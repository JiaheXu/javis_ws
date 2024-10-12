# //////////////////////////////////////////////////////////////////////////////
# javis common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
# ARG BASE_DOCKER_IMAGE
# Ubuntu 18.04 with nvidia-docker2 beta opengl support
FROM nvcr.io/nvidia/l4t-ml:r36.2.0-py3

# //////////////////////////////////////////////////////////////////////////////
# general tools install

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update --no-install-recommends \ 
    && apt-get install -y apt-utils 

RUN apt-get install -y \
  build-essential \
  cmake \
  cppcheck \
  gdb \
  git \
  lsb-release \
  software-properties-common \
  sudo \
  vim \
  wget \
  tmux \
  curl \
  less \
  net-tools \
  byobu \
  libgl-dev \
  iputils-ping \
  nano \
  unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Add a user with the same user_id as the user outside the container
# Requires a docker build argument `user_id`
ARG user_id=$user_id
ENV USERNAME developer
RUN useradd -U --uid ${user_id} -ms /bin/bash $USERNAME \
 && echo "$USERNAME:$USERNAME" | chpasswd \
 && adduser $USERNAME sudo \
 && echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME

# Commands below run as the developer user
USER $USERNAME

# When running a container start in the developer's home folder
WORKDIR /home/$USERNAME

# Set the timezone
RUN export DEBIAN_FRONTEND=noninteractive \
 && sudo apt-get update \
 && sudo -E apt-get install -y \
   tzdata \
 && sudo ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
 && sudo dpkg-reconfigure --frontend noninteractive tzdata \
 && sudo apt-get clean 



RUN mkdir ~/.javis

RUN touch ~/.Xauthority

RUN sudo usermod -a -G dialout developer \
 && sudo usermod -a -G tty developer \
 && sudo usermod -a -G video developer \
 && sudo usermod -a -G root developer


# for ros2
RUN sudo apt update && sudo apt install locales \
 && sudo locale-gen en_US en_US.UTF-8 \
 && sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
 && export LANG=en_US.UTF-8

RUN sudo apt install software-properties-common \
 && sudo add-apt-repository universe \
 && sudo apt update && sudo apt install curl -y \
 && sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

#need to comment out for basestations
RUN sudo apt purge --autoremove -y \
    opencv-dev \
    opencv-libs \
    opencv-licenses \
    opencv-main \
    opencv-python \
    opencv-scripts  

RUN sudo apt update && sudo apt upgrade -y \
 && sudo apt install -y \
    ros-humble-desktop \
    ros-dev-tools 

RUN python3 -m pip install --upgrade pip \
 && pip3 install --no-cache-dir ipdb ipython

# RUN pip3 install numpy==1.26.1 

# 2D Body pose detection.
# Mayank and Aniket.
# We should try to relax the versions a little bit.
RUN pip3 install --no-cache-dir \
    nvitop==1.3.2 \
    mmdet==2.24.1 \
    mmpose==0.25.1 \
    opencv-python==4.6.0.66 \
    opencv-python-headless==4.8.0.74 \ 
    openmim==0.1.5 \
    timm==0.5.4 \
    gradio==4.16.0 

# didn't find compatable ones
# RUN pip3 install mmcv-full==1.5.0 

# Heart rate detection.
# James.
RUN pip3 install --no-cache-dir \
    h5py \
    facenet_pytorch

# Alertness detectin.
# Krisha.
RUN pip3 install --no-cache-dir \
    sentencepiece~=0.1.98 \
    "transformers>=4.35.2,<5.0.0" \
    gguf>=0.1.0

# Bayes Tree.
# Kyle.
RUN pip3 install --no-cache-dir \
    pgmpy

# RUN sudo apt install python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
# RUN sudo apt install python3-rosdep
# RUN sudo rosdep init
# RUN rosdep update

RUN sudo apt install python3-colcon-common-extensions \
 ros-humble-rviz2 ros-humble-turtle-tf2-py ros-humble-tf2-ros ros-humble-tf2-tools ros-humble-turtlesim -y
