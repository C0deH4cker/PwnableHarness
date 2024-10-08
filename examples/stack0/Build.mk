# A Build.mk file can contain directory-specific variables such as
# TARGET as well as target-specific variables like stack0_CFLAGS.
# A bare minimum Build.mk file defines only TARGET.
#
# The build system defines the variable DIR to be the path to the
# directory containing Build.mk so it can be used to refer to files.
# This variable is useful because the actual current working directory
# of the build system is always at the top-level.


## Directory-specific variables

# TARGET is the name of the executable to build. If more than one
# target should be built, TARGETS should be set instead of TARGET.
# TARGET and TARGETS are actually handled in exactly the same way
# by the build system, but they both exist for user preference.
#
# Note: It is an error to define both TARGET and TARGETS.
TARGET := stack0


## Target-specific variables: Each of the following variables of the
# format target_VAR are specific to that target. If the variable is
# set without the target prefix, it will be applied to every target
# defined in this file unless a target defines the version with the
# target prefix, in which case only that target will use its own.
#
# For example, in the following example, both slowpoke and lethargic
# will be built with -O0, while gottagofast will be built with -O3.
#
# TARGETS := slowpoke lethargic gottagofast
# OFLAGS := -O0 -DSPEED=not_fast
# gottagofast_OFLAGS := -O3 -DSPEED=fast


# These are the variables may be defined here to override
# their defaults:
#
# CFLAGS:          Command line options passed to CC when compiling
#                    C source files.
#                  Default: empty
#
# LDFLAGS:         Command line options passed to LD when linking the
#                    TARGET executable.
#                  Default: empty
#
# OFLAGS:          Command line options passed to CC to control the
#                    compiler's optimization settings.
#                  Default: -O0
#
# NX:              Define this to enable NX aka DEP aka W^X.
#                  Default: empty
#
# ASLR:            Define this to enable ASLR.
#                  Default: empty
#
# CANARY:          Define this to enable stack protector canaries.
#                  Default: empty
#
# RELRO:           Define this to enable full RELRO. This can be set
#                    to "partial" to enable partial RELRO, which is
#                    the default in GCC.
#                  Default: empty
#
# STRIP:           Define this to strip symbols from the binary.
#                  Default: empty
#
# DEBUG:           Define this to include debugger symbols.
#                  Default: empty
#
# BITS:            Either 32 or 64, for deciding the architecture to
#                    build for (i386/amd64).
#                  Default: 64
BITS := 32
#
# CXXFLAGS:        Command line options passed to CXX when compiling
#                    C++ source files.
#                  Default: empty
#
# SRCS:            List of source files belonging to the TARGET.
#                  Default: Every file matching *.c or *.cpp in the
#                    same directory as Build.mk.
#
# CC:              Compiler to use for C sources.
#                  Default: gcc
#
# CXX:             Compiler to use for C++ sources.
#                  Default: g++
#
# LD:              Linker to use.
#                  Default: target_CXX if there are any C++ source
#                    files in target_SRCS, otherwise target_CC.
#
# BINTYPE:         Type of binary to build, either "dynamiclib" or
#                    "executable". You can set this to "custom" if
#                    you wish to provide your own linker rule.
#                    However, this is discouraged if it can be
#                    avoided.
#                  Default: "dynamiclib" if target ends in ".so",
#                    otherwise "executable".
#
# LIBS:            List of dynamic libraries to link against.
#                  Default: Empty unless USE_LIBPWNABLEHARNESS is
#                    defined, in which case the relevant 32/64-bit
#                    version of libpwnableharness*.so is used.


# PUBLISH is a list of files within this directory to publish when
# running "make publish". By default, PUBLISH is empty.
#
# PUBLISH_BUILD is a list of files from this project's build directory
# to publish when running "make publish". By default, PUBLISH_BUILD is
# empty. Setting this to the value of TARGET will copy the challenge
# binary to the publish directory.
#
# Note: "make publish" will copy every file listed to be published
# to the directory named "publish" in the top level of the workspace.
# This feature is useful for publishing files to a web server to
# instantly update challenges as they are rebuilt. The recommended way
# of doing that is to put symlinks in /var/www that point back into
# the publish directory in your workspace.
PUBLISH := stack0.c
PUBLISH_BUILD := $(TARGET)

# PUBLISH_LIBC is the desired filename used when publishing this
# challenge's libc. When this is defined, the exact libc used will
# be published to publish/$(DIR)/$(PUBLISH_LIBC). This libc will be
# copied from the docker image if the challenge is configured to run
# in docker, otherwise the local system's libc will be copied.
#PUBLISH_LIBC := stack0-libc.so

# DOCKER_IMAGE is the name of the docker image to create when
# running "make docker-build".
#
# Note: If DOCKER_IMAGE is not defined, no docker rules will be
# created for this directory.
DOCKER_IMAGE := c0deh4cker/stack0

# DOCKER_IMAGE_TAG is the tag to use for the Docker image.
# Default: latest
DOCKER_IMAGE_TAG := 2.0

# DOCKER_BUILD_ARGS is a list of name=value pairs that will be passed
# with --build-arg to docker build when "make docker-build" is run.
# These variables will be usable in a Dockerfile with ARG.
#DOCKER_BUILD_ARGS :=

# DOCKER_BUILD_DEPS is a list of Makefile dependencies that when changed
# will require the Docker image to be rebuilt. For example, if a challenge
# provides its own Dockerfile which is based on c0deh4cker/pwnableharness
# and copies the file "foo.bin" into the image:
#DOCKER_BUILD_DEPS := $(DIR)/foo.bin

# If DOCKER_RUNNABLE is defined at all, this docker image will be
# considered runnable.
#
# Note: If any of the variables DOCKER_RUNTIME_NAME, DOCKER_PORTS,
# DOCKER_RUN_ARGS, or DOCKER_ENTRYPOINT_ARGS are defined, then
# DOCKER_RUNNABLE will be assumed to be defined to true.
#DOCKER_RUNNABLE := true

# DOCKER_RUNTIME_NAME is used as the name of the user to create and
# use for handling connections, the executable to run when the docker
# container is started, and the running container.
#
# Note: If the docker image is considered to be runnable, then
# DOCKER_RUNTIME_NAME will default to the value of TARGET or the
# first item in TARGETS.
#DOCKER_RUNTIME_NAME := stack0

# DOCKER_PORTS is a list of ports to publish to the host when this
# docker container is run using "make docker-start".
#
# stack0 listens on port 32101, so bind that to the host.
DOCKER_PORTS := 32101

# DOCKER_TIMELIMIT defines the number of seconds that the target program
# will run before being killed. This is implemented by calling the
# alarm() syscall with this value as the seconds parameter. If this is
# set to 0 (which is the default if left undefined), then there will
# be no timelimit set.
DOCKER_TIMELIMIT := 30

# DOCKER_RUN_ARGS is a list of extra arguments to pass to "docker run".
#
# Mount the root filesystem of the container as read only.
# (NOW USING DOCKER_WRITEABLE INSTEAD)
#DOCKER_RUN_ARGS := --read-only

# DOCKER_WRITEABLE is used to make the Docker container's filesystem
# writeable. By default, the Docker container's filesystem is read-only.
#DOCKER_WRITEABLE := true

# DOCKER_ENTRYPOINT_ARGS is a list of arguments to pass to the docker
# container's ENTRYPOINT. This is only useful for custom Dockerfiles.
#DOCKER_ENTRYPOINT_ARGS :=

# [DEPRECATED] USE_LIBPWNABLEHARNESS is used to tell PwnableHarness that
# the targets expect to directly link against libpwnableharness in the old
# style. By default, libpwnableharness*.so is no longer linked to your
# targets. The new way of using PwnableHarness is for your program to just
# talk over stdin/stdout directly and doesn't require any code changes.
# PwnableHarness will even make sure to set stdout/stderr as unbuffered,
# so you don't need to manually add calls to fflush(stdout) in your code.
#USE_LIBPWNABLEHARNESS := true

# DEPLOY_COMMAND is a string containing a command that should be run during
# `make deploy` from the project directory.
#DEPLOY_COMMAND := echo "[DEPLOY] Dockerfile is: `cat Dockerfile`"

# DEPLOY_DEPS is a list of Makefile dependencies that should be up to date
# before the DEPLOY_COMMAND is run.
#DEPLOY_DEPS := $(DIR)/flag1.txt
