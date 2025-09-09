# //////////////////////////////////////////////////////////////////////////////
# javis common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
# ARG BASE_DOCKER_IMAGE


ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM dustynv/ollama:main-r36.4.0

RUN apt update

# RUN apt install software-properties-common -y \
#  && apt update && apt install curl -y \
#  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
#  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Add a user with the same user_id as the user outside the container
# Requires a docker build argument `user_id`


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

ARG user_id=$user_id
ENV USERNAME developer
RUN useradd -U --uid ${user_id} -ms /bin/bash $USERNAME \
 && echo "$USERNAME:$USERNAME" | chpasswd \
 && adduser $USERNAME sudo \
#  && mkdir /etc/sudoers.d/ \
#  && touch /etc/sudoers.d/$USERNAME \
 && echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME
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

#RUN pip3 install cv_bridge opencv-python

# RUN mkdir -p /home/developer/data/models/huggingface

ENV TRANSFORMERS_CACHE=/home/developer/model_data/models/huggingface \
    HUGGINGFACE_HUB_CACHE=/home/developer/model_data/models/huggingface \
    HF_HOME=/home/developer/model_data/models/huggingface

RUN sudo chmod -R 777 /dev

RUN sudo usermod -a -G dialout developer \
 && sudo usermod -a -G tty developer \
 && sudo usermod -a -G video developer \
 && sudo usermod -a -G root developer \
 && sudo groupadd -f -r gpio \
 && sudo usermod -a -G gpio developer \
 && sudo groupadd -f -r i2c \
 && sudo usermod -a -G i2c developer

