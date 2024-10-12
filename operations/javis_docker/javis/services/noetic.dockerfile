# //////////////////////////////////////////////////////////////////////////////
# javis common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG BASE_DOCKER_IMAGE
# Ubuntu 18.04 with nvidia-docker2 beta opengl support
FROM $BASE_DOCKER_IMAGE

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

# //////////////////////////////////////////////////////////////////////////////
# ros install
RUN sudo /bin/sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list' \
 && sudo /bin/sh -c 'wget -q http://packages.osrfoundation.org/gazebo.key -O - | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 sudo apt-key add -' \
 && sudo /bin/sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
 && sudo /bin/sh -c 'apt-key adv --keyserver  hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' \
 && sudo /bin/sh -c 'apt-key adv --keyserver keys.gnupg.net --recv-key C8B3A55A6F3EFCDE || apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C8B3A55A6F3EFCDE' \
 && sudo apt-get update --fix-missing

RUN sudo apt-get install -y --no-install-recommends \
  libboost-all-dev \
  python3-catkin-tools \
  gazebo11 \
  libgazebo11-dev \
  libignition-common-dev \
  libignition-math4-dev

#need to comment out for basestations
RUN sudo apt purge -y opencv-dev opencv-libs opencv-licenses opencv-main opencv-python opencv-scripts --autoremove 
RUN sudo apt-get install -y --no-install-recommends \
  ros-noetic-desktop-full 

RUN sudo apt-get install -y --no-install-recommends \  
  ros-noetic-rqt-gui \
  ros-noetic-rqt-gui-cpp \
  ros-noetic-rosmon \
  libboost-all-dev \
  libeigen3-dev \
  python3-rosdep \
  python3-rosinstall \
  ros-noetic-joy \
  ros-noetic-pointcloud-to-laserscan \
  ros-noetic-robot-localization \
  ros-noetic-spacenav-node \
  ros-noetic-tf2-sensor-msgs \
  ros-noetic-twist-mux \
  ros-noetic-octomap-ros \
  ros-noetic-octomap-server \
  ros-noetic-tf-conversions \
  ros-noetic-velodyne-description \
  ros-noetic-velodyne-simulator\ 
  assimp-utils \
  libcgal-dev \
  libcgal-qt5-dev \
  libproj-dev \
  libnlopt-dev \
  libncurses5-dev \
  libignition-transport4-dev \
  python3-wstool \
  # gazebo \
  ros-noetic-gazebo-* \
  ros-noetic-hector-sensors-description \
  ros-noetic-joint-state-controller \
  # ros-noetic-message-to-tf \
  ros-noetic-octomap \
  ros-noetic-octomap-server \
  # ros-noetic-octomap-rviz-plugins \
  ros-noetic-octomap-ros \
  ros-noetic-octomap-mapping \
  ros-noetic-octomap-msgs \
  ros-noetic-velodyne-* \
  libglfw3-dev libblosc-dev libopenexr-dev \
  ros-noetic-smach-viewer \
  ros-noetic-fkie-master-sync \
  ros-noetic-fkie-master-discovery \
  ros-noetic-random-numbers \
  liblog4cplus-dev \
  cmake \
  libsuitesparse-dev \
  libsdl1.2-dev \
  doxygen \
  graphviz \
  python3-requests \
  ros-noetic-mavros-msgs \
  ros-noetic-rosserial \
  ros-noetic-catch-ros \
  ros-noetic-teleop-twist-joy \
  ros-noetic-rosfmt \
  ros-noetic-jsk-rviz* \
  #################### \
  # state est rosdeps  \
  #################### \
  libpcap0.8-dev \
  libgoogle-glog-dev \
  libpcl-dev \
  python-tk \
  gstreamer1.0-plugins-base \
  gir1.2-gst-plugins-base-1.0 \
  libgstreamer1.0-dev \
  festival \
  festvox-kallpc16k \
  gstreamer1.0-plugins-ugly \
  python-gi \
  gstreamer1.0-plugins-good \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-tools \
  gir1.2-gstreamer-1.0 \
  chrony \
  sharutils \
  graphviz \
  python-setuptools \
  python3-pip \
  ros-noetic-gazebo-msgs \
  ####################\
  # python3 deps      \
  ####################\
  python3-pip \
  python3-empy \
  python3-setuptools \
  python3-pyqt5 \
  python3-pyqt5.qtsvg \
  python3-pydot \
  python3-tk \
  scrot \
  libdrm-dev \
  ansible

RUN sudo usermod -a -G dialout developer
RUN sudo usermod -a -G tty developer
RUN sudo usermod -a -G video developer
RUN sudo usermod -a -G root developer

RUN sudo ln -s /usr/include/sdformat-6.3/sdf /usr/include/sdf

# //////////////////////////////////////////////////////////////////////////////
# javis workspace deps.

# python3 deps
RUN sudo -H pip3 install --upgrade pip
RUN sudo -H pip3 install ifcfg wheel setuptools pexpect cython PyYAML jinja2  defusedxml netifaces python-dotenv graphviz opencv-python==4.6.0.66 pyserial xdot pycairo python-xlib
RUN sudo -H pip3 install numpy==1.19.4 scipy psutil pyquaternion rosdep rospkg rosinstall_generator rosinstall wstool vcstools catkin_tools catkin_pkg SIP python-dotenv Jinja2 pyautogui pyqtgraph install loguru h5py dotmap overrides utm rosnumpy sk-video
RUN sudo ln -sf /usr/bin/python3 /usr/bin/python

RUN sudo apt update && sudo apt install -y liborocos-kdl-dev python3-pykdl autoconf bc build-essential g++-8 gcc-8 clang-8 lld-8 gettext-base gfortran-8 iputils-ping libbz2-dev libc++-dev libcgal-dev libffi-dev libfreetype6-dev libhdf5-dev libjpeg-dev liblzma-dev libncurses5-dev libncursesw5-dev libpng-dev libreadline-dev libssl-dev libsqlite3-dev libxml2-dev libxslt-dev locales moreutils openssl python-openssl rsync scons python3-pip libopenblas-dev
RUN (sudo rosdep init && rosdep update) || echo failed

RUN mkdir -p /tmp/temp_ws

#Adding boost 1.80.0
# RUN cd /tmp/temp_ws/
RUN wget -qO /tmp/temp_ws/boost_1_80_0.tar.bz2 "https://boostorg.jfrog.io/artifactory/main/release/1.80.0/source/boost_1_80_0.tar.bz2"
RUN tar -xvf /tmp/temp_ws/boost_1_80_0.tar.bz2 -C /tmp/temp_ws/
RUN sudo /bin/bash -c "cd /tmp/temp_ws/boost_1_80_0 && ./bootstrap.sh --prefix=/usr/ && ./b2 -j8"

#Adding nlohmann
# RUN cd /tmp/temp_ws/
RUN git clone https://github.com/nlohmann/json.git /tmp/temp_ws/json
RUN mkdir -p /tmp/temp_ws/json/build
RUN sudo /bin/bash -c "cd /tmp/temp_ws/json/build && cmake .. && make -j8 && make install"

# Clean up :)
RUN sudo apt-get clean \
 && sudo rm -rf /var/lib/apt/lists/*

# RUN sudo apt update && sudo apt install -y python3-tf2-ros

# copy all the code found the thirdparty directory
COPY --chown=$USERNAME:$USERNAME thirdparty-software/ /home/$USERNAME/thirdparty-software/

# entrypoint env vars
ARG arch=$arch
ENV entrypoint_container_path /docker-entrypoint/

# add entrypoint scripts (general & system specific)
ADD entrypoints/ $entrypoint_container_path/
ADD $arch/entrypoints/ $entrypoint_container_path/

# execute entrypoint script
RUN sudo chmod +x -R $entrypoint_container_path/

# create empty /home/$USER/.javis directory, to avoid mounting as root in compose volume mount
RUN mkdir ~/.javis

# create ~/.Xauthority
RUN touch ~/.Xauthority

# RUN mkdir -p ~/thirdparty-software && cd ~/thirdparty-software

# RUN git clone --recursive https://github.com/opencv/opencv.git opencv -b 4.5.0

# RUN git clone --recursive https://github.com/opencv/opencv_contrib.git opencv_contrib -b 4.5.0

# RUN mkdir -p ~/thirdparty-software/opencv/build && cd ~/thirdparty-software/opencv/build

# RUN cmake \
#    -D CMAKE_CXX_STANDARD=14 \
#    -D CMAKE_CXX_STANDARD_REQUIRED=ON \
#    -D WITH_CUDA=OFF \
#    -D WITH_CUDNN=OFF \
#    -D WITH_CUBLAS=OFF \
#    -D CUDA_ARCH_BIN=8.7 \
#    -D CUDA_ARCH_PTX="" \
#    -D CUDA_FAST_MATH=OFF \
#    -D OPENCV_DNN_CUDA=OFF \
#    -D ENABLE_NEON=ON \
#    -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
#    -D OPENCV_GENERATE_PKGCONFIG=ON \
#    -D BUILD_opencv_python3=ON \
#    -D OPENCV_ENABLE_NONFREE=ON \
#    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
#    -D WITH_GSTREAMER=ON \
#    -D WITH_V4L=ON \
#    -D WITH_OPENGL=ON \
#    -D BUILD_TESTS=OFF \
#    -D BUILD_PERF_TESTS=OFF \
#    -D BUILD_EXAMPLES=OFF \
#    -D CMAKE_BUILD_TYPE=RELEASE \
#    -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
#    sudo make install -j4

# set image to run entrypoint script
ENTRYPOINT $entrypoint_container_path/docker-entrypoint.bash