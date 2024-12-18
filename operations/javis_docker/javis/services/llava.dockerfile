# //////////////////////////////////////////////////////////////////////////////
# javis common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
# ARG BASE_DOCKER_IMAGE


ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM dustynv/llava:r36.2.0
# for ros2
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


RUN sudo apt update && sudo apt upgrade -y \
 && sudo apt install -y ros-humble-ros-base ros-dev-tools 
RUN sudo apt-get install -y --no-install-recommends \
    blt ca-certificates-java default-jdk default-jdk-headless default-jre default-jre-headless \
    default-libmysqlclient-dev fonts-lyx gdal-data gir1.2-ibus-1.0 java-common libaom-dev \
    libarmadillo-dev libarmadillo10 libarpack2 libarpack2-dev libasound2 libasound2-data \
    libasound2-dev libassimp-dev libassimp5 libasyncns0 libavcodec-dev libavformat-dev libavutil-dev \
    libblkid-dev libblosc-dev libblosc1 libboost-all-dev libboost-atomic-dev libboost-atomic1.74-dev \
    libboost-atomic1.74.0 libboost-chrono-dev libboost-chrono1.74-dev libboost-chrono1.74.0 \
    libboost-container-dev libboost-container1.74-dev libboost-container1.74.0 libboost-context-dev \
    libboost-context1.74-dev libboost-context1.74.0 libboost-coroutine-dev libboost-coroutine1.74-dev \
    libboost-coroutine1.74.0 libboost-date-time-dev libboost-date-time1.74-dev \
    libboost-date-time1.74.0 libboost-dev libboost-exception-dev libboost-exception1.74-dev \
    libboost-fiber-dev libboost-fiber1.74-dev libboost-fiber1.74.0 libboost-filesystem-dev \
    libboost-filesystem1.74-dev libboost-filesystem1.74.0 libboost-graph-dev \
    libboost-graph-parallel-dev libboost-graph-parallel1.74-dev libboost-graph-parallel1.74.0 \
    libboost-graph1.74-dev libboost-graph1.74.0 libboost-iostreams-dev libboost-iostreams1.74-dev \
    libboost-iostreams1.74.0 libboost-locale-dev libboost-locale1.74-dev libboost-locale1.74.0 \
    libboost-log-dev libboost-log1.74-dev libboost-log1.74.0 libboost-math-dev libboost-math1.74-dev \
    libboost-math1.74.0 libboost-mpi-dev libboost-mpi-python-dev libboost-mpi-python1.74-dev \
    libboost-mpi-python1.74.0 libboost-mpi1.74-dev libboost-mpi1.74.0 libboost-nowide-dev \
    libboost-nowide1.74-dev libboost-nowide1.74.0 libboost-numpy-dev libboost-numpy1.74-dev \
    libboost-numpy1.74.0 libboost-program-options-dev libboost-program-options1.74-dev \
    libboost-program-options1.74.0 libboost-python-dev libboost-python1.74-dev libboost-python1.74.0 \
    libboost-random-dev libboost-random1.74-dev libboost-random1.74.0 libboost-regex-dev \
    libboost-regex1.74-dev libboost-serialization-dev libboost-serialization1.74-dev \
    libboost-serialization1.74.0 libboost-stacktrace-dev libboost-stacktrace1.74-dev \
    libboost-stacktrace1.74.0 libboost-system-dev libboost-system1.74-dev libboost-system1.74.0 \
    libboost-test-dev libboost-test1.74-dev libboost-test1.74.0 libboost-thread-dev \
    libboost-thread1.74-dev libboost-thread1.74.0 libboost-timer-dev libboost-timer1.74-dev \
    libboost-timer1.74.0 libboost-tools-dev libboost-type-erasure-dev libboost-type-erasure1.74-dev \
    libboost-type-erasure1.74.0 libboost-wave-dev libboost-wave1.74-dev libboost-wave1.74.0 \
    libboost1.74-dev libboost1.74-tools-dev libbrotli-dev libcfitsio-dev libcfitsio9 libcharls-dev \
    libcharls2 libclang1-14 libdav1d-dev libdbus-1-dev libdc1394-25 libdc1394-dev libde265-0 \
    libde265-dev libdecor-0-0 libdecor-0-dev libdeflate-dev libdouble-conversion-dev \
    libdouble-conversion3 libdraco-dev libdraco4 libdrm-amdgpu1 libdrm-dev libdrm-etnaviv1 \
    libdrm-freedreno1 libdrm-nouveau2 libdrm-radeon1 libdrm-tegra0 libegl-dev libegl-mesa0 libegl1 \
    libegl1-mesa-dev libevdev2 libexif-dev libexif12 libflann-dev libflann1.9 libfontconfig-dev \
    libfontconfig1-dev libfreetype-dev libfreetype6-dev libfreexl-dev libfreexl1 libfyba-dev libfyba0 \
    libgbm-dev libgbm1 libgdal-dev libgdal30 libgdcm-dev libgdcm3.0 libgeos-c1v5 libgeos-dev \
    libgeos3.10.2 libgeotiff-dev libgeotiff5 libgif-dev libgl-dev libgl1 libgl1-mesa-dev \
    libgl1-mesa-dri libgl2ps-dev libgl2ps1.4 libglapi-mesa libgles-dev libgles1 libgles2 libglew-dev \
    libglew2.2 libglib2.0-dev libglib2.0-dev-bin libglu1-mesa libglu1-mesa-dev libglvnd-core-dev \
    libglvnd-dev libglvnd0 libglx-dev libglx-mesa0 libglx0 libgphoto2-6 libgphoto2-dev \
    libgphoto2-port12 libgudev-1.0-0 libhdf4-0-alt libhdf4-alt-dev libhdf5-mpi-dev \
    libhdf5-openmpi-103-1 libhdf5-openmpi-cpp-103-1 libhdf5-openmpi-dev libhdf5-openmpi-fortran-102 \
    libhdf5-openmpi-hl-100 libhdf5-openmpi-hl-cpp-100 libhdf5-openmpi-hl-fortran-100 libheif-dev \
    libheif1 libhyphen0 libibus-1.0-5 libibus-1.0-dev libice-dev libignition-cmake2-dev \
    libignition-math6 libignition-math6-dev libilmbase-dev libilmbase25 libimagequant0 libinput-bin \
    libinput10 libjbig-dev libjson-c-dev libjsoncpp-dev libkml-dev libkmlbase1 libkmlconvenience1 \
    libkmldom1 libkmlengine1 libkmlregionator1 libkmlxsd1 liblbfgsb0 libllvm15 liblz4-dev liblzma-dev \
    libmd4c0 libminizip-dev libminizip1 libmount-dev libmtdev1 libmysqlclient-dev libmysqlclient21 \
    libnetcdf-c++4 libnetcdf-cxx-legacy-dev libnetcdf-dev libnetcdf19 libnspr4 libnss3 libodbc2 \
    libodbccr2 libodbcinst2 libogdi-dev libogdi4.1 libogg-dev \
    libopenni-dev libopenni0 libopenni2-0 libopenni2-dev libpcap0.8 libpciaccess-dev libpcl-apps1.12 \
    libpcl-common1.12 libpcl-dev libpcl-features1.12 libpcl-filters1.12 libpcl-io1.12 \
    libpcl-kdtree1.12 libpcl-keypoints1.12 libpcl-ml1.12 libpcl-octree1.12 libpcl-outofcore1.12 \
    libpcl-people1.12 libpcl-recognition1.12 libpcl-registration1.12 libpcl-sample-consensus1.12 \
    libpcl-search1.12 libpcl-segmentation1.12 libpcl-stereo1.12 libpcl-surface1.12 \
    libpcl-tracking1.12 libpcl-visualization1.12 libpcre16-3 libpcre2-16-0 libpcre2-32-0 libpcre2-dev \
    libpcre2-posix3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libpcsclite1 libpng-dev libpoppler-dev \
    libpoppler-private-dev libpoppler118 libpq-dev libpq5 libproj-dev libproj22 libprotobuf23 \
    libpthread-stubs0-dev libpulse-dev libpulse-mainloop-glib0 libpulse0 libpyside2-dev \
    libpyside2-py3-5.15 libqhull-dev libqhull-r8.0 libqhull8.0 libqhullcpp8.0 libqt5concurrent5 \
    libqt5core5a libqt5dbus5 libqt5designer5 libqt5designercomponents5 libqt5gui5 libqt5help5 \
    libqt5network5 libqt5opengl5 libqt5opengl5-dev libqt5positioning5 libqt5printsupport5 libqt5qml5 \
    libqt5qmlmodels5 libqt5qmlworkerscript5 libqt5quick5 libqt5quickparticles5 libqt5quickshapes5 \
    libqt5quicktest5 libqt5quickwidgets5 libqt5sensors5 libqt5sql5 libqt5sql5-sqlite libqt5svg5 \
    libqt5test5 libqt5webchannel5 libqt5webkit5 libqt5webkit5-dev libqt5widgets5 libqt5xml5 libraqm0 \
    libraw1394-11 libraw1394-dev librttopo-dev librttopo1 libsdl2-2.0-0 libsdl2-dev libselinux1-dev \
    libsensors-config libsensors5 libsepol-dev libshiboken2-dev libshiboken2-py3-5.15 libsm-dev \
    libsndio-dev libsndio7.0 libsocket++1 libspatialite-dev libspatialite7 libsuperlu-dev libsuperlu5 \
    libswresample-dev libswscale-dev libtbb-dev libtbb2 libtcl8.6 libtheora-dev libtiff-dev \
    libtiffxx5 libtk8.6 libudev-dev liburiparser-dev liburiparser1 libusb-1.0-0 libusb-1.0-0-dev \
    libutfcpp-dev libvtk9-dev libvtk9-java libvtk9-qt-dev libvtk9.1 libvtk9.1-qt libvulkan-dev \
    libvulkan1 libwacom-common libwacom9 libwayland-bin libwayland-dev libwayland-server0 libwebp-dev \
    libwebpdemux2 libwoff1 libx11-dev libx11-xcb1 libx265-dev libxau-dev libxaw7-dev libxcb-dri2-0 \
    libxcb-dri3-0 libxcb-glx0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-present0 \
    libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 \
    libxcb-xinerama0 libxcb-xinput0 libxcb-xkb1 libxcb1-dev libxcursor-dev libxdmcp-dev \
    libxerces-c-dev libxerces-c3.2 libxext-dev libxfixes-dev libxft-dev libxft2 libxi-dev \
    libxinerama-dev libxkbcommon-dev libxkbcommon-x11-0 libxmu-dev libxmu-headers libxpm-dev \
    libxrandr-dev libxrender-dev libxshmfence1 libxsimd-dev libxss-dev libxss1 libxt-dev libxtst6 \
    libxv-dev libxv1 libxxf86vm-dev libxxf86vm1 mailcap mime-support mpi-default-bin mpi-default-dev \
    mysql-common openjdk-11-jdk openjdk-11-jdk-headless openjdk-11-jre openjdk-11-jre-headless \
    proj-data pyqt5-dev python-matplotlib-data python3-appdirs python3-beniget python3-brotli \
    python3-cairo python3-cycler python3-decorator python3-fonttools python3-fs python3-gast \
    python3-kiwisolver python3-lz4 python3-matplotlib python3-mpi4py python3-mpmath \
    python3-pil python3-pil.imagetk python3-ply python3-pydot python3-pyqt5 python3-pyqt5.qtsvg \
    python3-pyqt5.sip python3-pyside2.qtcore python3-pyside2.qtgui python3-pyside2.qtsvg \
    python3-pyside2.qtwidgets python3-pythran python3-scipy python3-sip python3-sip-dev python3-sympy \
    python3-tk python3-tz python3-ufolib2 python3-unicodedata2 python3-vtk9 qdoc-qt5 \
    qhelpgenerator-qt5 qt5-assistant qt5-qmake qt5-qmake-bin qt5-qmltooling-plugins \
    qtattributionsscanner-qt5 qtbase5-dev qtbase5-dev-tools qtchooser qtdeclarative5-dev \
    qtdeclarative5-dev-tools qttools5-dev qttools5-dev-tools qttools5-private-dev \
    ros-humble-action-tutorials-cpp ros-humble-action-tutorials-interfaces \
    ros-humble-action-tutorials-py ros-humble-angles ros-humble-composition \
    ros-humble-demo-nodes-cpp ros-humble-demo-nodes-cpp-native ros-humble-demo-nodes-py \
    ros-humble-dummy-map-server \
    ros-humble-dummy-robot-bringup ros-humble-dummy-sensors ros-humble-example-interfaces \
    ros-humble-examples-rclcpp-minimal-action-client ros-humble-examples-rclcpp-minimal-action-server \
    ros-humble-examples-rclcpp-minimal-client ros-humble-examples-rclcpp-minimal-composition \
    ros-humble-examples-rclcpp-minimal-publisher ros-humble-examples-rclcpp-minimal-service \
    ros-humble-examples-rclcpp-minimal-subscriber ros-humble-examples-rclcpp-minimal-timer \
    ros-humble-examples-rclcpp-multithreaded-executor ros-humble-examples-rclpy-executors \
    ros-humble-examples-rclpy-minimal-action-client ros-humble-examples-rclpy-minimal-action-server \
    ros-humble-examples-rclpy-minimal-client ros-humble-examples-rclpy-minimal-publisher \
    ros-humble-examples-rclpy-minimal-service ros-humble-examples-rclpy-minimal-subscriber \
    ros-humble-ignition-cmake2-vendor ros-humble-ignition-math6-vendor \
    ros-humble-image-transport ros-humble-interactive-markers \
    ros-humble-joy ros-humble-laser-geometry ros-humble-libcurl-vendor \
    ros-humble-lifecycle ros-humble-logging-demo ros-humble-map-msgs ros-humble-pcl-conversions \
    ros-humble-pcl-msgs ros-humble-pendulum-control ros-humble-pendulum-msgs \
    ros-humble-python-qt-binding ros-humble-qt-dotgraph ros-humble-qt-gui ros-humble-qt-gui-cpp \
    ros-humble-qt-gui-py-common ros-humble-quality-of-service-demo-cpp \
    ros-humble-quality-of-service-demo-py ros-humble-resource-retriever ros-humble-rqt-action \
    ros-humble-rqt-bag ros-humble-rqt-bag-plugins \
    ros-humble-rqt-console ros-humble-rqt-graph ros-humble-rqt-gui ros-humble-rqt-gui-cpp \
    ros-humble-rqt-gui-py ros-humble-rqt-msg ros-humble-rqt-plot \
    ros-humble-rqt-publisher ros-humble-rqt-py-common ros-humble-rqt-py-console \
    ros-humble-rqt-reconfigure ros-humble-rqt-service-caller ros-humble-rqt-shell ros-humble-rqt-srv \
    ros-humble-rqt-topic ros-humble-rttest ros-humble-rviz-assimp-vendor ros-humble-rviz-common \
    ros-humble-rviz-default-plugins ros-humble-rviz-ogre-vendor ros-humble-rviz-rendering \
    ros-humble-rviz2 ros-humble-sdl2-vendor ros-humble-sensor-msgs-py ros-humble-tango-icons-vendor \
    ros-humble-teleop-twist-joy ros-humble-teleop-twist-keyboard ros-humble-tlsf ros-humble-tlsf-cpp \
    ros-humble-topic-monitor ros-humble-turtlesim shiboken2 sip-dev tango-icon-theme tcl tcl-dev \
    tcl8.6 tcl8.6-dev tk tk-dev tk8.6 tk8.6-blt2.5 tk8.6-dev unicode-data unixodbc-common \
    unixodbc-dev uuid-dev vtk9 x11proto-dev xorg-sgml-doctools xtrans-dev \
    ros-humble-rosbag2-storage-mcap \
    ros-humble-ament-lint-auto \
    ros-humble-ament-cmake-cppcheck \
    ros-humble-ament-cmake-cpplint \
    ros-humble-ament-cmake-uncrustify \
    ros-humble-ament-cmake-flake8 \
    ros-humble-ament-cmake-pep257 \
    ros-humble-ament-cmake-xmllint \
    ros-humble-common-interfaces \
    ros-humble-camera-info-manager


RUN pip3 install cv_bridge opencv-python

RUN mkdir -p /home/developer/data/models/huggingface

ENV TRANSFORMERS_CACHE=/home/developer/data/models/huggingface \
    HUGGINGFACE_HUB_CACHE=/home/developer/data/models/huggingface \
    HF_HOME=/home/developer/data/models/huggingface

RUN sudo chmod -R 777 /dev

RUN sudo usermod -a -G dialout developer \
 && sudo usermod -a -G tty developer \
 && sudo usermod -a -G video developer \
 && sudo usermod -a -G root developer \
 && sudo groupadd -f -r gpio \
 && sudo usermod -a -G gpio developer \
 && sudo groupadd -f -r i2c \
 && sudo usermod -a -G i2c developer