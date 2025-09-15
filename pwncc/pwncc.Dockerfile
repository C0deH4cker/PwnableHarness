# Keep the default value aligned with DEFAULT_UBUNTU_VERSION in Macros.mk!
ARG BASE_IMAGE=ubuntu:24.04
FROM $BASE_IMAGE
LABEL maintainer="c0deh4cker@gmail.com"

# BuilderImage.mk will set this depending on if the base image has 32-bit support
ARG CONFIG_IGNORE_32BIT=
ARG TARGETARCH

# The Ubuntu repos for old, unsupported versions of Ubuntu are offline. Modify
# the APT sources for these to use the old-releases.ubuntu.com server.
# https://stackoverflow.com/a/65301993
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "Updating repos..."; \
if ! apt-get update >/dev/null 2>&1; then \
	if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
		apt_list_file=/etc/apt/sources.list.d/ubuntu.sources; \
	else \
		apt_list_file=/etc/apt/sources.list; \
	fi; \
	sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' "$apt_list_file"; \
	apt-get update >/dev/null; \
fi \
	&& apt-get install -y \
		build-essential \
		clang \
		$(test -z "$CONFIG_IGNORE_32BIT" && [ "$TARGETARCH" != "arm64" ] && echo "gcc-multilib") \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /PwnableHarness
