# //////////////////////////////////////////////////////////////////////////////
# javis loam dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

# SuperOdom deps
RUN sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
        libgoogle-glog-dev \
        libgflags-dev \
        libatlas-base-dev \
        libsuitesparse-dev \
        libparmetis-dev \
    && sudo apt-get clean 

# Install Gtsam 
RUN cd ~/thirdparty-software\
 && git clone https://github.com/borglab/gtsam.git --branch 4.0.3\
 && cd gtsam \
 && mkdir build && cd build \
 && cmake -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF ..\
 && sudo make install -j8 \
 && cd ~ 
 #&& sudo rm -rf ~/thirdparty-software/gtsam

RUN cd ~/thirdparty-software \
 && git clone http://github.com/strasdat/Sophus.git \
 && cd Sophus && git checkout 97e7161 \
 && mkdir build && cd build && cmake .. -DBUILD_TESTS=OFF \
 && make -j8 && sudo make install

RUN sudo apt install -y libeigen3-dev libfmt-dev
#  && sed -i '32,33d' sophus/so2.cpp \
#  && sed -i '31 a unit_complex_ = std::complex<double>(1,0);' sophus/so2.cpp 

# Add developer user to groups to run drivers
# RUN sudo usermod -a -G dialout developer
# RUN sudo usermod -a -G tty developer
# RUN sudo usermod -a -G video developer
# RUN sudo usermod -a -G root developer

# RUN sudo apt-get update --no-install-recommends \
#  && sudo apt-get install -y \
#   libpcap0.8 \
#   libpcap0.8-dbg \
#   libpcap0.8-dev \
#   libpcap-dev \
#   gstreamer1.0-plugins-good \
#   gstreamer1.0-plugins-bad \
#   gstreamer1.0-libav



RUN export BAZEL_VERSION=5.2.0 \
 && sudo wget -q https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-linux-arm64 -O /usr/bin/bazel \
 && sudo chmod a+x /usr/bin/bazel

# Install Ceres solver
RUN cd ~/thirdparty-software \
 && wget ceres-solver.org/ceres-solver-2.0.0.tar.gz \
 && tar xvf ceres-solver-2.0.0.tar.gz \
 && cd ceres-solver-2.0.0 \
 && mkdir build && cd build \
 && cmake .. \
 && sudo make install -j8 \
 && cd ~ 
 #&& sudo rm -rf ~/thirdparty-software/ceres-solver 

RUN cd ~/thirdparty-software \
 && git clone https://github.com/ethz-asl/libnabo \
 && cd libnabo && git checkout 2cc265088d31cf81092ef39215236b9f8838f499 \
 && mkdir build && cd build \
 && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. \
 && make -j8 \
 && sudo make install