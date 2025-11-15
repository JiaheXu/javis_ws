# //////////////////////////////////////////////////////////////////////////////
# javis common, ros melodic dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
# ARG BASE_DOCKER_IMAGE


ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM jiahexu98/whisper_trt_ros2:v0


# bash: /opt/ros/humble/setup.bash: No such file or directory
# bash: /home/developer/javis_ws/src/whisper_ws/install/setup.bash: No such file or directory