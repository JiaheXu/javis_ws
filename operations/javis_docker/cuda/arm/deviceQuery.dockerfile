FROM arm64v8/ubuntu:16.04

ARG arch=$arch

ENV LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/tegra
RUN mkdir /cudaSamples
COPY $arch/deviceQuery/deviceQuery /cudaSamples/

CMD /cudaSamples/deviceQuery