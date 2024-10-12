# //////////////////////////////////////////////////////////////////////////////
# javis common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG BASE_DOCKER_IMAGE
# Ubuntu 18.04 with nvidia-docker2 beta opengl support
FROM $BASE_DOCKER_IMAGE

# //////////////////////////////////////////////////////////////////////////////
# general tools install
RUN apt-get update --no-install-recommends \
 && apt-get install -y \
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

RUN mkdir /home/${USERNAME}/dds_install
RUN mkdir /tmp/dds_downloads

### The links below will work until March 28, 2022 at which point they will need updated :) - Josh
ARG ARCH_T
RUN /bin/bash -c "[[ ! \"$ARCH_T\" == \"arm\" ]] \
  || (wget -qO /tmp/dds_downloads/rti_connext_dds-6.0.1.zip \"https://javis.blob.core.windows.net/docker/dds/rti_connext_dds-6.0.1.zip?sp=r&st=2022-04-29T14:11:28Z&se=2025-04-29T22:11:28Z&sv=2020-08-04&sr=b&sig=hMwjjAr1E8UkABDErz5KMB%2BmKsRt09JHyuCiixcu9wU%3D\" \
  && unzip /tmp/dds_downloads/rti_connext_dds-6.0.1.zip -d /home/\${USERNAME}/dds_install)"

RUN /bin/bash -c "[[ ! \"$ARCH_T\" == \"x86\" ]] \
  || (wget -qO /tmp/dds_downloads/rti_connext_dds-6.0.0.zip \"https://javis.blob.core.windows.net/docker/dds/rti_connext_dds-6.0.0.zip?sp=r&st=2022-04-29T14:09:03Z&se=2025-04-29T22:09:03Z&sv=2020-08-04&sr=b&sig=ylsc894SkbA7desJcDrbpubA5o%2Bpb0JWV7z1DhW%2B2qw%3D\" \
  && unzip /tmp/dds_downloads/rti_connext_dds-6.0.0.zip -d /home/\${USERNAME}/dds_install)"

RUN /bin/bash -c "[[ ! \"$ARCH_T\" == \"x86\" ]] \
  || (wget -qO /tmp/dds_downloads/ros-data-types-x86.zip \"https://javis.blob.core.windows.net/docker/dds/ros-data-types-x86.zip?sp=r&st=2022-12-20T01:08:28Z&se=2024-12-20T09:08:28Z&sv=2021-06-08&sr=b&sig=OAWmDLgm8ooY3rlLBti9lZeyJP2aytZNxmWFsV6VHc0%3D\" \
  && unzip /tmp/dds_downloads/ros-data-types-x86.zip -d /home/\${USERNAME}/dds_install)"

RUN /bin/bash -c "[[ ! \"$ARCH_T\" == \"arm\" ]] \
  || (wget -qO /tmp/dds_downloads/ros-data-types-arm.zip \"https://javis.blob.core.windows.net/docker/dds/ros-data-types-arm.zip?sp=r&st=2022-12-20T01:06:23Z&se=2024-12-20T09:06:23Z&sv=2021-06-08&sr=b&sig=xTci%2Bb0TABIENS39OTWdW1DZHTtB%2FNb52lM7nNpa4sQ%3D\" \
  && unzip /tmp/dds_downloads/ros-data-types-arm.zip -d /home/\${USERNAME}/dds_install)"

RUN rm -rf /tmp/dds_downloads

RUN cd /home/developer/dds_install/rti_connext_dds* && \
    rm -rf include/persistence include/recordingservice include/routingservice include/rti include/rti_dl && \
    rm -rf doc && \
    rm -rf lib/java && \
    rm -rf resource/app resource/cert resource/idl resource/schema resource/scripts resource/template resource/xml && \
    rm -rf README.html RTI_License_Agreement.pdf bin rtilauncher.desktop uninstall

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
 && sudo /bin/sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros1-latest.list' \
 && sudo /bin/sh -c 'apt-key adv --keyserver  hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' \
 && sudo /bin/sh -c 'apt-key adv --keyserver keys.gnupg.net --recv-key C8B3A55A6F3EFCDE || apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C8B3A55A6F3EFCDE' \
 && sudo apt-get update \
 && sudo apt-get install -y --no-install-recommends \
  python-rosdep \
  libboost-all-dev \
  python-wstool \
  python-catkin-tools \
  gazebo9 \
  libgazebo9-dev \
  libignition-common-dev \
  libignition-math4-dev \
  ros-melodic-rqt-gui \
  ros-melodic-rqt-gui-cpp \
  ros-melodic-rosmon \
  python-rosinstall \
  ros-melodic-desktop-full \
  ros-melodic-joystick-drivers \
  ros-melodic-pointcloud-to-laserscan \
  ros-melodic-robot-localization \
  ros-melodic-spacenav-node \
  ros-melodic-tf2-sensor-msgs \
  ros-melodic-twist-mux \
  ros-melodic-velodyne-simulator \
  libboost-all-dev \
  libeigen3-dev \
  assimp-utils \
  libcgal-dev \
  libcgal-qt5-dev \
  ros-melodic-octomap-ros \
  libproj-dev \
  libnlopt-dev \
  libncurses5-dev \
  ros-melodic-octomap-server \
  libignition-transport4-dev \
  ros-melodic-velodyne-description \
  python-wstool \
  ros-melodic-tf-conversions \
  # gazebo \
  ros-melodic-gazebo-* \
  ros-melodic-hector-sensors-description \
  ros-melodic-joint-state-controller \
  # ros-melodic-message-to-tf \
  ros-melodic-octomap \
  ros-melodic-octomap-server \
  # ros-melodic-octomap-rviz-plugins \
  ros-melodic-octomap-ros \
  ros-melodic-octomap-mapping \
  ros-melodic-octomap-msgs \
  ros-melodic-velodyne-* \
  libglfw3-dev libblosc-dev libopenexr-dev \
  ros-melodic-smach-viewer \
  ros-melodic-multimaster-fkie \
  ros-melodic-random-numbers \
  liblog4cplus-dev \
  cmake \
  libsuitesparse-dev \
  libsdl1.2-dev \
  doxygen \
  graphviz \
  ros-melodic-mav-msgs \
  python-requests \
  ros-melodic-mavros-msgs \
  ros-melodic-rosserial \
  ros-melodic-catch-ros \
  ros-melodic-teleop-twist-joy \
  ros-melodic-rosfmt \
  ros-melodic-jsk-rviz* \
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
  python-pip \
  ros-melodic-gazebo-msgs \
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
  ansible

RUN sudo ln -s /usr/include/sdformat-6.3/sdf /usr/include/sdf

# //////////////////////////////////////////////////////////////////////////////
# javis workspace deps.
RUN python -m pip install cython wheel setuptools pexpect python-dotenv --user
RUN python -m pip install numpy PyYAML pyquaternion Jinja2 --user

# python3 deps
RUN sudo -H pip3 install --upgrade pip
RUN sudo -H pip3 install ifcfg wheel setuptools pexpect cython jinja2  defusedxml netifaces python-dotenv graphviz opencv-python==4.6.0.66 pyserial xdot pycairo
RUN sudo -H pip3 install numpy==1.19.4 scipy psutil pyquaternion rosdep rospkg rosinstall_generator rosinstall wstool vcstools catkin_tools catkin_pkg SIP python-dotenv Jinja2 pyautogui pyqtgraph
RUN sudo rm /usr/bin/python && sudo ln /usr/bin/python3.6 /usr/bin/python

# RUN sudo apt update && sudo apt install -y liborocos-kdl-dev

# RUN git clone https://github.com/foolyc/PyKDL.git /tmp/pykdl
# RUN sudo /bin/bash -c "cd /tmp/pykdl && chmod +x install.sh && ./install.sh"

RUN (sudo rosdep init && rosdep update) || echo failed

# Some build arguments



# ARG CATKIN_PROFILE_ARCH
# ENV ROS_PYTHON_VERSION 3
# ENV CATKIN_BUILD_ARGS "-DCMAKE_BUILD_TYPE=Release -DPYTHON_VERSION=3.6 -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY:FILEPATH=/usr/lib/${CATKIN_PROFILE_ARCH}/libpython3.6m.so"

RUN mkdir -p /tmp/temp_ws/src
# RUN git clone https://github.com/ros/geometry2.git /tmp/temp_ws/src/geometry2
# RUN git clone https://github.com/clearpathrobotics/spot_ros.git /tmp/temp_ws/src/spot_ros
RUN git clone https://github.com/orocos/orocos_kinematics_dynamics.git /tmp/temp_ws/src/orocos_kd
RUN cd /tmp/temp_ws/src/orocos_kd && git checkout a2bbe913ebd74cdf65f1ab4cebc87465dacac08d && git submodule update --init --recursive
# RUN touch /tmp/temp_ws/src/orocos_kd/orocos_kdl/CATKIN_IGNORE
RUN mkdir -p /tmp/temp_ws/src/orocos_kd/orocos_kdl/build
RUN sudo /bin/bash -c "cd /tmp/temp_ws/src/orocos_kd/orocos_kdl/build && cmake .. && make -j8 && make install"
# RUN sudo /bin/bash -c "cd /tmp/temp_ws/ && source /opt/ros/melodic/setup.bash && catkin_make ${CATKIN_BUILD_ARGS} && catkin_make install ${CATKIN_BUILD_ARGS} -DCMAKE_INSTALL_PREFIX=/opt/ros/melodic"
# RUN sudo rm -rf /tmp/temp_ws


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

# set image to run entrypoint script
ENTRYPOINT $entrypoint_container_path/docker-entrypoint.bash
