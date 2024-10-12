# //////////////////////////////////////////////////////////////////////////////
# javis general drivers dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

# //////////////////////////////////////////////////////////////////////////////
# driver dependencies
RUN sudo apt-get update --no-install-recommends \
 && sudo apt-get install -y \
  ros-noetic-mavros \
  ros-noetic-mavros-extras \
  ros-noetic-joy \
  ros-noetic-teleop-twist-joy

# RUN sudo -H pip uninstall -y pyyaml
# RUN sudo -H pip3 install pyyaml

# Add developer user to groups to run drivers
RUN sudo usermod -a -G dialout developer
RUN sudo usermod -a -G tty developer
RUN sudo usermod -a -G video developer
RUN sudo usermod -a -G root developer

# install mavros deps
COPY --chown=$USERNAME:$USERNAME thirdparty-software/ /home/$USERNAME/thirdparty-software/
RUN cd /home/$USERNAME/thirdparty-software/ \
 && sudo ./install_geographiclib_datasets.sh

RUN sudo apt-get update --no-install-recommends \
 && sudo apt-get install -y \
  libpcap0.8 \
  libpcap0.8-dbg \
  libpcap0.8-dev \
  libpcap-dev \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-libav

RUN sudo -H pip3 install \
  # gas sensor (javis payload ver 1)
  #adafruit-circuitpython-bme680 \
  # gas sensor (javis payload ver 2)
  #adafruit-circuitpython-scd30 \
  Jetson.GPIO

# Install boston dynamics spot api
RUN sudo -H pip3 install wrapt
RUN sudo -H pip3 install bosdyn-client bosdyn-mission bosdyn-api bosdyn-core
RUN sudo apt install -y ros-noetic-interactive-marker-twist-server ros-noetic-joint-state-publisher-gui

RUN sudo apt-get update && sudo apt-get install -y \
    vim \
    libatlas-base-dev \
    libeigen3-dev \
    libgoogle-glog-dev \
    libsuitesparse-dev \
    python3-catkin-tools python3-osrf-pycommon \
    python3-matplotlib \
    gfortran \
    autoconf \
    git \
    coinor-libipopt-dev \
    curl \
    libopenmpi-dev \
    apt-utils \
    software-properties-common \
    build-essential \
    libssl-dev \
    wget \
    openssh-client \
    ros-noetic-desktop-full \
    ros-noetic-cv-bridge \
    ros-noetic-rviz \
    ros-noetic-robot-state-publisher \
    ros-noetic-image-transport \
    ros-noetic-message-filters \
    ros-noetic-tf \
    zsh \
    ros-noetic-ros-control \
    ros-noetic-gazebo-ros \
    ros-noetic-gazebo-ros-pkgs \
    ros-noetic-gazebo-ros-control \
    ros-noetic-joy \
    ros-noetic-ros-controllers \
    ros-noetic-plotjuggler \
    ros-noetic-plotjuggler-ros  \
    ros-noetic-interactive-markers \
    ros-noetic-roslint \
    ros-noetic-rqt-controller-manager \
    ros-noetic-xacro \
    clang-format \
    clang-tidy

RUN sudo apt-get update && sudo apt-get install cmake --upgrade

# ocs2 dependencies
RUN sudo apt-get update \
    && sudo apt-get install -y libglpk-dev ros-noetic-pybind11-catkin \
    liburdfdom-dev liboctomap-dev libassimp-dev doxygen doxygen-latex

# install python 3.8 but do not break python 2.7 otherwise ros will break
RUN sudo apt-get update && \
    sudo apt-get install -y python3.8 python3.8-dev ipython3
RUN sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1  && \
    curl https://bootstrap.pypa.io/pip/get-pip.py -o get-pip.py  && \
    python3 get-pip.py  && \
    rm get-pip.py  && \
    pip3 --version

ENV TZ=America/New_York
#RUN sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN cd ~/thirdparty-software \
 && git clone --recursive https://github.com/oxfordcontrol/osqp -b release-0.6.2 \
 && cd osqp \
 && mkdir build && cd build \
 && cmake -G "Unix Makefiles" .. \
 && cmake --build . \
 && sudo cmake --build . --target install

# add OSQP-python
RUN pip install osqp && \
    sudo apt-get install -y ipython3 wget

# add osqp-eigen
RUN cd ~/thirdparty-software \
 && git clone https://github.com/robotology/osqp-eigen.git \
 && cd osqp-eigen \
 && mkdir build && cd build \ 
 && cmake .. \
 && make \
 && sudo make install


RUN cd ~/thirdparty-software \
  && git clone https://github.com/lcm-proj/lcm.git && \
    cd lcm && \
    git checkout tags/v1.4.0 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    sudo make install 

ENV UNITREE_SDK_VERSION=3_8
RUN cd ~/thirdparty-software \
  && git clone https://github.com/unitreerobotics/unitree_legged_sdk.git && \
    cd unitree_legged_sdk && git checkout v3.8.0 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make 

RUN cd ~/thirdparty-software \
 && git clone --depth 1 https://github.com/MRSD-DarkBot/aliengo_sdk && \
    cd aliengo_sdk && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make

ENV UNITREE_LEGGED_SDK_PATH=~/thirdparty-software/unitree_legged_sdk
ENV ALIENGO_SDK_PATH=~/thirdparty-software/aliengo_sdk
ENV UNITREE_PLATFORM=arm64


RUN cd ~/thirdparty-software \
 && git clone https://github.com/casadi/casadi.git && \
    cd casadi && git checkout tags/3.5.5 && \
    mkdir build && cd build && \
    cmake -DWITH_CPLEX=OFF -DWITH_KNITRO=OFF -DWITH_OOQP=OFF -DWITH_SNOPT=OFF ~/thirdparty-software/casadi && \
    make && \
    sudo make install

RUN cd ~/thirdparty-software \
 && git clone https://github.com/ShuoYangRobotics/gram_savitzky_golay.git \
 && cd gram_savitzky_golay \
 && git submodule init \
 && git submodule update \
 && mkdir build && cd build \
 && cmake -DCMAKE_BUILD_TYPE=Release ../ \
 && make && sudo make install


 # realsense
RUN sudo apt-get install ros-noetic-ddynamic-reconfigure
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
RUN sudo add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" -u
RUN sudo apt-get install librealsense2-utils -y
RUN sudo apt-get install librealsense2-dev -y 

# # Clean up
# RUN sudo apt-get clean \
#  && sudo rm -rf /var/lib/apt/lists/*




