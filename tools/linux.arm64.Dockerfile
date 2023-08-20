FROM --platform=arm64 ubuntu:22.04 

RUN apt-get update
RUN apt install xz-utils wget \
    generate-ninja=0.0~git20220118.0725d78-1 \
    ninja-build=1.10.1-1 \
    build-essential=12.9ubuntu3 \
    ccache=4.5.1-1 \
    make=4.3-4.1build1 \
    zlib1g-dev=1:1.2.11.dfsg-2ubuntu9.2 \
    pkg-config=0.29.2-1ubuntu3 \
    -y
RUN apt install -y pkg-config libglib2.0-dev
WORKDIR /opt
RUN wget https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz
RUN tar xf zig-linux-aarch64-0.11.0.tar.xz
ENV PATH "$PATH:/opt/zig-linux-aarch64-0.11.0"