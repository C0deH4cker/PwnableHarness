# Keep aligned with DEFAULT_UBUNTU_VERSION in Macros.mk!
FROM ubuntu:24.04
LABEL maintainer="c0deh4cker@gmail.com"

# Add necessary and useful packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y \
		binutils \
		curl \
		git \
		gosu \
		htop \
		make \
		net-tools \
		netcat-traditional \
		python3 \
		python3-launchpadlib \
		vim \
	&& rm -rf /var/lib/apt/lists/*

# Make the "sudo" command work as scripts would normally expect
ARG DIR
COPY $DIR/pwnmake-sudo.sh /usr/sbin/sudo
COPY $DIR/pwnmake-in-container /usr/bin/pwnmake
COPY $DIR/pwnmake-entrypoint.sh /pwnmake-entrypoint.sh
RUN chmod 4755 /usr/sbin/gosu \
&& chmod +x /usr/sbin/sudo \
&& chmod +x /usr/bin/pwnmake

# Yes, we really want to have gosu be setuid root. This is just a builder
# container, only used for challenge development and management (not runtime).
# https://github.com/tianon/gosu/blob/4233b796eeb3ba76c8597a46d89eab1f116188e2/main.go#L48
ENV GOSU_PLEASE_LET_ME_BE_COMPLETELY_INSECURE_I_GET_TO_KEEP_ALL_THE_PIECES="I've seen things you people wouldn't believe. Attack ships on fire off the shoulder of Orion. I watched C-beams glitter in the dark near the Tannhäuser Gate. All those moments will be lost in time, like tears in rain. Time to die."

# Set up PwnableHarness top-level directory and workspace location
WORKDIR /PwnableHarness/workspace

# Copy in the root PwnableHarness files
COPY \
	.dockerignore \
	get_supported_ubuntu_versions.py \
	Macros.mk \
	Makefile \
	UbuntuVersions.mk \
	core \
	/PwnableHarness/

# Tell the top-level Makefile that this is a container build
ENV CONTAINER_BUILD=1

ARG TARGETARCH
ENV DOCKER_ARCH=$TARGETARCH

ARG GIT_HASH=missing
ARG VERSION=missing
RUN echo ${GIT_HASH} > /PwnableHarness/.githash \
	&& echo ${VERSION} > /PwnableHarness/.version

# Wrapper script may pass arguments to the entrypoint
ENTRYPOINT [ "/pwnmake-entrypoint.sh" ]
