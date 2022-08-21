FROM ubuntu:20.04
LABEL maintainer="c0deh4cker@gmail.com"

# Add compilers and support for building 32-bit executables
RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		curl \
		gosu \
		build-essential \
		clang \
		gcc-multilib \
		git \
		vim \
		htop \
	&& rm -rf /var/lib/apt/lists/*

# Make the "sudo" command work as scripts would normally expect
COPY builder-sudo.sh /usr/sbin/sudo
RUN chmod 4755 /usr/sbin/gosu \
	&& chmod +x /usr/sbin/sudo

# Set up PwnableHarness top-level directory and workspace location
WORKDIR /PwnableHarness/workspace

# This should mirror the list of files marked as dependencies in
# the top-level Build.mk file.
COPY .dockerignore \
	Build.mk \
	builder-entrypoint.sh \
	Dockerfile \
	Macros.mk \
	Makefile \
	pwnable_harness.c \
	pwnable_harness.h \
	pwnable_server.c \
	stdio_unbuffer.c \
	/PwnableHarness/

# Tell the top-level Makefile that this is a container build
ENV CONTAINER_BUILD=1

# Wrapper script may pass arguments to the entrypoint
ENTRYPOINT [ "/PwnableHarness/builder-entrypoint.sh" ]
