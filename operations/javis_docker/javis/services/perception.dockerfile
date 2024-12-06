# //////////////////////////////////////////////////////////////////////////////
# javis loam dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

RUN sudo apt update && sudo apt install -y libnl-utils libtbb-dev

# SuperOdom deps
RUN sudo apt-get update \
    && sudo apt install -y --no-install-recommends \
    cmake \
    libgoogle-glog-dev \
    libgflags-dev \
    libatlas-base-dev \
    libeigen3-dev \
    libsuitesparse-dev \
    libparmetis-dev 


RUN wget -q  https://files.pythonhosted.org/packages/0c/00/1a14450d315a6f43728c40e3c15fb22648474106d98d06eec7994c6ccd2f/mediapipe-0.10.15-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl

RUN pip3 install mediapipe-0.10.15-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl

RUN mkdir /home/developer/thirdparty-software



RUN cd ~/thirdparty-software \
 && git clone http://github.com/strasdat/Sophus.git \
 && cd Sophus && git checkout 97e7161 \
 && mkdir build && cd build && cmake .. -DBUILD_TESTS=OFF \
 && make -j8 && sudo make install

RUN sudo apt install -y libeigen3-dev libfmt-dev


# RUN export BAZEL_VERSION=5.2.0 \
#  && sudo wget-q  -q https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-linux-arm64 -O /usr/bin/bazel \
#  && sudo chmod a+x /usr/bin/bazel

RUN cd ~/thirdparty-software \
 && git clone https://github.com/ethz-asl/libnabo \
 && cd libnabo && git checkout 2cc265088d31cf81092ef39215236b9f8838f499 \
 && mkdir build && cd build \
 && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. \
 && make -j8 \
 && sudo make install

# # Install Ceres solver
RUN cd ~/thirdparty-software \
 && git clone https://github.com/JiaheXu/ceres-solver.git \
 && cd ceres-solver \
 && mkdir build && cd build \
 && cmake .. \
 && sudo make install -j8 \
 && cd ~ 
 #&& sudo rm -rf ~/thirdparty-software/ceres-solver

 

# Install Gtsam 
RUN cd ~/thirdparty-software\
  && git clone https://github.com/borglab/gtsam.git \
  && cd gtsam && git checkout 4abef92\
  && mkdir build && cd build \
  && cmake -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF .. \
  && sudo make install -j8 \
  && cd ~ 
  #&& sudo rm -rf ~/thirdparty-software/gtsam