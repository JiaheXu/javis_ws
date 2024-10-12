# please run this inside docker javis_estimation

# install opencv and opencv_contrib
cd ~/thirdparty-software

git clone --recursive https://github.com/opencv/opencv.git opencv -b 4.5.0

git clone --recursive https://github.com/opencv/opencv_contrib.git opencv_contrib -b 4.5.0

mkdir -p ~/thirdparty-software/opencv/build && cd ~/thirdparty-software/opencv/build

cmake \
   -D CMAKE_CXX_STANDARD=14 \
   -D CMAKE_CXX_STANDARD_REQUIRED=ON \
   -D WITH_CUDA=ON \
   -D WITH_CUDNN=ON \
   -D WITH_CUBLAS=ON \
   -D CUDA_ARCH_BIN=8.7 \
   -D CUDA_ARCH_PTX="" \
   -D CUDA_FAST_MATH=ON \
   -D OPENCV_DNN_CUDA=ON \
   -D ENABLE_NEON=ON \
   -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
   -D OPENCV_GENERATE_PKGCONFIG=ON \
   -D BUILD_opencv_python3=ON \
   -D OPENCV_ENABLE_NONFREE=ON \
   -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
   -D WITH_GSTREAMER=ON \
   -D WITH_V4L=ON \
   -D WITH_OPENGL=ON \
   -D BUILD_TESTS=OFF \
   -D BUILD_PERF_TESTS=OFF \
   -D BUILD_EXAMPLES=OFF \
   -D CMAKE_BUILD_TYPE=RELEASE \
   -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
   sudo make install -j4
# cmake \
#    -D CMAKE_CXX_STANDARD=14 \
#    -D CMAKE_CXX_STANDARD_REQUIRED ON \
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


