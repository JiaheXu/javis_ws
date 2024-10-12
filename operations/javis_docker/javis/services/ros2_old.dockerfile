# //////////////////////////////////////////////////////////////////////////////
# airlab common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG BASE_DOCKER_IMAGE
# Ubuntu 20.04 with nvidia-docker2 beta opengl support
FROM $BASE_DOCKER_IMAGE

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


# for zed camera, need root access
RUN apt-get update || true 
RUN apt-get install --no-install-recommends lsb-release wget less udev zstd sudo apt-transport-https build-essential cmake -y

# need to comment out for basestation
# RUN    wget -q --no-check-certificate -O ZED_SDK_Linux.run https://download.stereolabs.com/zedsdk/4.0/l4t35.1/jetsons 
# RUN chmod +x ZED_SDK_Linux.run ; ./ZED_SDK_Linux.run silent skip_tools skip_drivers && \
#     rm -rf /usr/local/zed/resources/* \
#     rm -rf ZED_SDK_Linux.run && \
#     rm -rf /var/lib/apt/lists/*
# RUN ln -sf /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 /usr/lib/aarch64-linux-gnu/libv4l2.so

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

# for ros2 humble
RUN sudo apt update && sudo apt install locales \
 && sudo locale-gen en_US en_US.UTF-8 \
 && sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
 && export LANG=en_US.UTF-8

RUN sudo apt install software-properties-common -y
RUN sudo add-apt-repository universe

# RUN sudo apt install software-properties-common && sudo add-apt-repository universe
RUN sudo apt update && sudo apt install curl -y
RUN sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# RUN sudo apt update && sudo apt upgrade -y
# RUN sudo apt install ros-galactic-desktop ros-dev-tools -y


RUN sudo apt update && sudo apt install -y \
  python3-flake8-docstrings \
  python3-pip \
  python3-pytest-cov \
  python3-dev \
  ros-dev-tools \
  dialog \
  apt-utils

RUN sudo python3 -m pip install -U \
    flake8-blind-except \
    flake8-builtins \
    flake8-class-newline \
    flake8-comprehensions \
    flake8-deprecated \
    flake8-import-order \
    flake8-quotes \
    "pytest>=5.3" \
    pytest-repeat \
    pytest-rerunfailures \
    setuptools==61.0.0 \
    # human body detection
    numpy==1.23.5 \
    opencv-python==4.6.0.66 \
    opencv-python-headless==4.8.0.74 

RUN mkdir -p /home/$USERNAME/thirdparty-software/ros2_humble/src && cd /home/$USERNAME/thirdparty-software/ros2_humble/

# RUN mkdir -p  && cd ros2_humble
RUN sudo vcs import --input https://raw.githubusercontent.com/ros2/ros2/humble/ros2.repos /home/$USERNAME/thirdparty-software/ros2_humble/src

# RUN sudo chown -R developer:developer /usr/local/lib/python3.8/dist-packages
RUN sudo chown -R developer:developer /usr/local
# RUN sudo chown -R developer:developer /usr/local/lib/python3.8/dist-packages/pyzed-4.0.dist-info
# RUN sudo chmod 777 /usr/local/lib/python3.8/dist-packages/pyzed-4.0.dist-info

# need to comment out for basestation
RUN sudo apt purge -y opencv-dev opencv-libs opencv-licenses opencv-main opencv-python opencv-scripts --autoremove 
# RUN sudo apt upgrade -y
RUN sudo rosdep init
RUN rosdep update

RUN rosdep install --from-paths /home/$USERNAME/thirdparty-software/ros2_humble/src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"

RUN sudo chown -R developer:developer /home/$USERNAME/thirdparty-software
# ENV PYTHON3_INCLUDE_DIRS=/usr/include/python3.8
# ENV PYTHON3_LIBRARIES=/usr/lib/python3.8/config-3.8-aarch64-linux-gnu/libpython3.8.so

RUN cd /home/$USERNAME/thirdparty-software/ros2_humble/  \
  && colcon build \
  --cmake-args \
    -DPython3_EXECUTABLE=/usr/bin/python3 \
    -DPYBIND11_PYTHON_VERSION=3 \
 && rm -rf ./build \
 && rm -rf ./log

# entrypoint env vars
ARG arch=$arch
ENV entrypoint_container_path /docker-entrypoint/

# add entrypoint scripts (general & system specific)
ADD entrypoints/ $entrypoint_container_path/
ADD $arch/entrypoints/ $entrypoint_container_path/

# execute entrypoint script
RUN sudo chmod +x -R $entrypoint_container_path/

# create empty /home/$USER/.airlab directory, to avoid mounting as root in compose volume mount
RUN mkdir ~/.javis

# create ~/.Xauthority
RUN touch ~/.Xauthority

# sudo apt install libpcl-dev
# sudo apt-get install libpcap-dev
# sudo apt-get install ros-humble-diagnostic-updater
# set image to run entrypoint script
ENTRYPOINT $entrypoint_container_path/docker-entrypoint.bash


# Add developer user to groups to run drivers
RUN sudo usermod -a -G dialout developer
RUN sudo usermod -a -G tty developer
RUN sudo usermod -a -G video developer
RUN sudo usermod -a -G root developer

RUN sudo groupadd -f -r gpio
RUN sudo usermod -a -G gpio developer

RUN sudo apt install libpcl-dev libpcap-dev -y
# # # might related to torch need to check on orin
# RUN sudo python3 -m pip install -U \
#     openmim==0.1.5 \
#     timm==0.5.4 \
#     gradio==4.16.0 \
#     wandb==0.16.2 \
#     mmcv-full==1.5.0 \
#     mmdet==2.24.1 \
#     mmpose==0.25.1 \
#     testresources \
#     nvitop==1.3.2
