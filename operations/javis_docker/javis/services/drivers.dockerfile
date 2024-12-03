# //////////////////////////////////////////////////////////////////////////////
# javis general drivers dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

# for lidar & usb cam
RUN sudo apt install -y \
    ros-humble-pcl-ros \
    ros-humble-tf2-eigen \
    ros-humble-rviz2 \
    build-essential \
    libeigen3-dev \
    libjsoncpp-dev \
    libspdlog-dev \
    libcurl4-openssl-dev \
    cmake \
    python3-colcon-common-extensions \
    ros-humble-rosbag2-storage-mcap \
    ros-humble-can-msgs \
    ros-humble-serial-driver \
#     # gstreamer
#     gir1.2-gst-plugins-bad-1.0 \
#     gir1.2-gst-plugins-base-1.0 \
#     gir1.2-gstreamer-1.0 \
#     gir1.2-gudev-1.0 \
#     gstreamer1.0-alsa \
#     gstreamer1.0-gtk3 \
#     gstreamer1.0-plugins-ugly \
#     gstreamer1.0-pulseaudio \
#     gstreamer1.0-qt5 \
#     gstreamer1.0-tools \
#     libgstreamer-plugins-base1.0-dev \
#     libgstreamer-plugins-good1.0-dev \
#     libgstreamer1.0-dev \
#     liba52-0.7.4 \
#     libcdio19 \
#     libdw-dev \
#     libelf-dev \
#     libgudev-1.0-dev \
#     libmpeg2-4 \
#     libopencore-amrnb0 \
#     libopencore-amrwb0 \
#     libopenexr-dev \
#     liborc-0.4-dev \
#     liborc-0.4-dev-bin \
#     libqt5waylandclient5 \
#     libqt5x11extras5 \
#     libsidplay1v5 \
#     libunwind-dev \
#     libx11-xcb-dev