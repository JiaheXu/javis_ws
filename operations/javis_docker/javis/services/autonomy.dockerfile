# //////////////////////////////////////////////////////////////////////////////
# javis autonomy dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

# //////////////////////////////////////////////////////////////////////////////
# javis workspace deps.
ARG ARCH_T
RUN /bin/bash -c "[[ ! $ARCH_T == x86 ]] || sudo -H pip3 install jax jaxlib"
RUN /bin/bash -c "[[ ! $ARCH_T == x86 ]] || sudo -H pip3 install --upgrade pip"
RUN /bin/bash -c "[[ ! $ARCH_T == x86 ]] || sudo -H pip3 install --upgrade jax jaxlib"

RUN sudo -H pip3 install pymavlink pymap3d