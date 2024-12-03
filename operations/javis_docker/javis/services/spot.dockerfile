# //////////////////////////////////////////////////////////////////////////////
# javis general drivers dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

#for spot
RUN pip3 install --no-warn-script-location \
    aiortc==1.5.0 \
    bosdyn-api==4.1.0 \
    bosdyn-choreography-client==4.1.0 \
    bosdyn-client==4.1.0 \
    bosdyn-core==4.1.0 \
    bosdyn-mission==4.1.0 \
    grpcio==1.59.3 \
    image==1.5.33 \
    inflection==0.5.1 \
    opencv-python>=4.5.4 \
    open3d==0.18.0 \
    protobuf==4.22.1 \
    pytest==7.3.1 \
    pytest-cov==4.1.0 \
    pytest-xdist==3.5.0 \
    pyyaml>=6.0 \
    setuptools==59.6.0


# Install ROS dependencies
# TODO(jschornak-bdai): use rosdep to install these packages by parsing dependencies listed in package.xml
ARG ROS_DISTRO=humble
RUN sudo apt update
RUN sudo apt install -y ros-humble-joint-state-publisher-gui ros-$ROS_DISTRO-xacro ros-$ROS_DISTRO-tl-expected
# ros-$ROS_DISTRO-depth-image-proc
# Install the dist-utils
RUN sudo apt-get install -y python3-distutils
RUN sudo apt-get install -y python3-apt
RUN pip3 install --force-reinstall -v "setuptools==59.6.0"

# ARG ARCH=$CPU_ARCH
# CMD if [ "$ARCH_T" = "x86"] ; then ARG ARCH="amd64"; else echo ARG ARCH="arm64" ; fi

ENV ARCH="arm64"
ARG SDK_VERSION="4.1.0"
ARG MSG_VERSION="${SDK_VERSION}-4"

RUN pip3 install \
    aiortc==1.5.0 \
    bosdyn-api==4.1.0 \
    bosdyn-choreography-client==4.1.0 \
    bosdyn-client==4.1.0 \
    bosdyn-core==4.1.0 \
    bosdyn-mission==4.1.0 \
    grpcio==1.59.3 \
    image==1.5.33 \
    inflection==0.5.1 \
    opencv-python>=4.5.4 \
    open3d==0.18.0 \
    protobuf==4.22.1 \
    pytest==7.3.1 \
    pytest-cov==4.1.0 \
    pytest-xdist==3.5.0 \
    pyyaml>=6.0 \
    setuptools==62.4.0

RUN sudo apt-get update

# Install ROS dependencies
# TODO(jschornak-bdai): use rosdep to install these packages by parsing dependencies listed in package.xml
# RUN sudo apt install -y ros-$ROS_DISTRO-joint-state-publisher-gui ros-$ROS_DISTRO-tf-transformations ros-$ROS_DISTRO-xacro ros-$ROS_DISTRO-depth-image-proc ros-$ROS_DISTRO-tl-expected ros-$ROS_DISTRO-ros2-control ros-$ROS_DISTRO-ros2-controllers
# Install the dist-utils
RUN sudo apt-get install -y python3-distutils
RUN sudo apt-get install -y python3-apt
# RUN sudo pip3 install --force-reinstall -v "setuptools==59.6.0"
RUN sudo apt install -y ros-humble-controller-interface ros-humble-forward-command-controller clang-tidy
RUN pip3 install cv-bridge

# Install bosdyn_msgs - automatic conversions of BD protobufs to ROS messages
RUN wget -q -O /tmp/ros-humble-bosdyn_msgs_${MSG_VERSION}-jammy_${ARCH}.run https://github.com/bdaiinstitute/bosdyn_msgs/releases/download/${MSG_VERSION}/ros-humble-bosdyn_msgs_${MSG_VERSION}-jammy_${ARCH}.run
RUN chmod +x /tmp/ros-humble-bosdyn_msgs_${MSG_VERSION}-jammy_${ARCH}.run
RUN yes | sudo /tmp/ros-humble-bosdyn_msgs_${MSG_VERSION}-jammy_${ARCH}.run  --nox11
RUN rm /tmp/ros-humble-bosdyn_msgs_${MSG_VERSION}-jammy_${ARCH}.run

# Install spot-cpp-sdk
RUN wget -q -O /tmp/spot-cpp-sdk_${SDK_VERSION}_${ARCH}.deb https://github.com/bdaiinstitute/spot-cpp-sdk/releases/download/v${SDK_VERSION}/spot-cpp-sdk_${SDK_VERSION}_${ARCH}.deb
RUN sudo dpkg -i /tmp/spot-cpp-sdk_${SDK_VERSION}_${ARCH}.deb
RUN rm /tmp/spot-cpp-sdk_${SDK_VERSION}_${ARCH}.deb

# ros-$ROS_DISTRO-depth-image-proc
RUN sudo apt install -y ros-$ROS_DISTRO-joint-state-publisher-gui ros-$ROS_DISTRO-tf-transformations ros-$ROS_DISTRO-xacro ros-$ROS_DISTRO-tl-expected ros-$ROS_DISTRO-ros2-control ros-$ROS_DISTRO-ros2-controllers
RUN wget -q -O /home/developer/protoc-29.0-rc-3-linux-aarch_64.zip https://github.com/protocolbuffers/protobuf/releases/download/v29.0-rc3/protoc-29.0-rc-3-linux-aarch_64.zip

RUN sudo rm -rf /usr/local/bin/protoc /usr/local/include/google /usr/local/lib/libproto*

RUN unzip protoc-29.0-rc-3-linux-aarch_64.zip -d /home/developer/.local
RUN echo "export PATH=$PATH:$HOME/.local/bin" >> ~/.bashrc 