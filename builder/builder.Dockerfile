# Keep this aligned with PWNABLE_BUILDER_DEFAULT_BASE in BuilderImage.mk!
ARG BASE_IMAGE=ubuntu:18.04
FROM $BASE_IMAGE
LABEL maintainer="c0deh4cker@gmail.com"

ARG BUILDARCH
ARG TARGETARCH
RUN echo "Building on ${BUILDARCH} for ${TARGETARCH}"

# BuilderImage.mk will set this depending on if the base image has 32-bit support
ARG CONFIG_IGNORE_32BIT=
ENV CONFIG_IGNORE_32BIT=$CONFIG_IGNORE_32BIT

# Add compilers and support for building 32-bit executables
RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		curl \
		gosu \
		python3 \
		python3-pip \
		build-essential \
		clang \
		git \
		vim \
		htop \
		$(test -z "$CONFIG_IGNORE_32BIT" && [ "$TARGETARCH" != "arm64" ] && echo "gcc-multilib") \
	&& rm -rf /var/lib/apt/lists/* \
	&& python3 -m pip install launchpadlib

# Make the "sudo" command work as scripts would normally expect
ARG DIR
COPY $DIR/builder-sudo.sh /usr/sbin/sudo
RUN chmod 4755 /usr/sbin/gosu \
	&& chmod +x /usr/sbin/sudo

# Set up PwnableHarness top-level directory and workspace location
WORKDIR /PwnableHarness/workspace

# Copy in the root PwnableHarness files
COPY \
	.dockerignore \
	Macros.mk \
	Makefile \
	builder/builder-entrypoint.sh \
	/PwnableHarness/

# Copy in the core PwnableHarness project files
COPY \
	core/base.Dockerfile \
	core/BaseImage.mk \
	core/Build.mk \
	core/get_supported_ubuntu_versions.py \
	core/pwnable_harness.c \
	core/pwnable_harness.h \
	core/pwnable_server.c \
	core/stdio_unbuffer.c \
	core/UbuntuVersions.mk \
	/PwnableHarness/core/

# Tell the top-level Makefile that this is a container build
ENV CONTAINER_BUILD=1

ENV DOCKER_ARCH=$TARGETARCH

ARG GIT_HASH=missing
ARG VERSION=missing
RUN echo ${GIT_HASH} > /PwnableHarness/.githash \
	&& echo ${VERSION} > /PwnableHarness/.version

# Wrapper script may pass arguments to the entrypoint
ENTRYPOINT [ "/PwnableHarness/builder-entrypoint.sh" ]
