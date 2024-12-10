# //////////////////////////////////////////////////////////////////////////////
# javis general drivers dockerfile -- version: 0.1
# //////////////////////////////////////////////////////////////////////////////
ARG JAVIS_ROS_DISTRO=$JAVIS_ROS_DISTRO
ARG ARCH_T=$ARCH_T
ARG DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION
FROM javis/${ARCH_T}.ros.${JAVIS_ROS_DISTRO}:${DOCKER_IMAGE_VERSION}

# RUN pip3 install --no-cache-dir \
#     h5py \
#     facenet_pytorch==2.5.3

# RUN python3 -m pip install --upgrade pip \
#     && pip3 install --no-cache-dir ipdb ipython

# # Alertness detectin.
# # Krisha.
# RUN pip3 install --no-cache-dir \
#     sentencepiece~=0.1.98 \
#     "transformers>=4.35.2,<5.0.0" \
#     gguf>=0.1.0