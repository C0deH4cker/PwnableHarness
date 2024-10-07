# Keep the default value aligned with DEFAULT_UBUNTU_VERSION in Macros.mk!
ARG BASE_IMAGE=ubuntu:24.04
FROM $BASE_IMAGE
LABEL maintainer="c0deh4cker@gmail.com"

# BuilderImage.mk will set this depending on if the base image has 32-bit support
ARG CONFIG_IGNORE_32BIT=
ENV CONFIG_IGNORE_32BIT=$CONFIG_IGNORE_32BIT

# Add compilers
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y \
		build-essential \
		clang \
		$(test -z "$CONFIG_IGNORE_32BIT" && [ "$TARGETARCH" != "arm64" ] && echo "gcc-multilib") \
	&& rm -rf /var/lib/apt/lists/*
