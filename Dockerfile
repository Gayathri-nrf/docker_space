FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake ninja-build git wget xz-utils gperf ccache dfu-util \
    device-tree-compiler file libsdl2-dev libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies for Zephyr/west
RUN pip install --no-cache-dir west pyyaml jsonschema pykwalify

WORKDIR /workspace

# Clone your app repo, then initialize west from the local clone
RUN git clone --branch main https://github.com/Gayathri-nrf/docker_space docker_space
RUN west init -l docker_space
RUN west update
RUN west zephyr-export

# Install Zephyr's Python requirements
RUN pip install --no-cache-dir -r /workspace/zephyr/scripts/requirements.txt

# Zephyr SDK (compilers, debuggers)
ARG SDK_VERSION=1.0.1
RUN mkdir -p /opt && \
    wget -q https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${SDK_VERSION}/zephyr-sdk-${SDK_VERSION}_linux-x86_64_gnu.tar.xz -O /tmp/sdk.tar.xz && \
    tar -xf /tmp/sdk.tar.xz -C /opt && \
    rm /tmp/sdk.tar.xz && \
    /opt/zephyr-sdk-${SDK_VERSION}/setup.sh -t arm-zephyr-eabi -h -c

ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${SDK_VERSION}

# Build the app for nRF52 DK
WORKDIR /workspace
CMD ["west", "build", "-b", "nrf52dk/nrf52832", "docker_space", "--pristine"]