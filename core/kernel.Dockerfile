# Base image for kernel pwn challenges.
# Provides QEMU + socat; the challenge's auto-generated Dockerfile
# inherits via FROM and the ONBUILD instructions handle the rest.

ARG BASE_TAG=24.04
FROM ubuntu:$BASE_TAG
LABEL maintainer="c0deh4cker@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        qemu-system-x86 \
        qemu-system-arm \
        qemu-system-mips \
        qemu-system-misc \
        socat \
        cpio \
    && rm -rf /var/lib/apt/lists/*

ARG DIR=core
COPY $DIR/serve-kernel.sh /usr/bin/serve-kernel
RUN chmod +x /usr/bin/serve-kernel

WORKDIR /challenge

# --- ONBUILD: executed when a challenge image is built FROM this base ---

# Kernel image and initramfs are supplied by the challenge author / build system
ONBUILD ARG KERNEL_IMAGE_PATH
ONBUILD ARG INITRAMFS_PATH
ONBUILD COPY $KERNEL_IMAGE_PATH /challenge/bzImage
ONBUILD COPY $INITRAMFS_PATH /challenge/initramfs.cpio.gz

# QEMU configuration (passed as Docker build-args by Macros.mk)
ONBUILD ARG PORT=9000
ONBUILD ARG TIMELIMIT=120
ONBUILD ARG QEMU_ARCH=x86_64
ONBUILD ARG QEMU_CPU=qemu64
ONBUILD ARG QEMU_MEM=512M
ONBUILD ARG QEMU_SMP=1
ONBUILD ARG KERNEL_CMDLINE="console=ttyS0 quiet panic=-1"

ONBUILD ENV PORT=$PORT \
    TIMELIMIT=$TIMELIMIT \
    QEMU_ARCH=$QEMU_ARCH \
    QEMU_CPU=$QEMU_CPU \
    QEMU_MEM=$QEMU_MEM \
    QEMU_SMP=$QEMU_SMP \
    KERNEL_CMDLINE=$KERNEL_CMDLINE

ONBUILD EXPOSE $PORT

ENTRYPOINT ["/usr/bin/serve-kernel"]
