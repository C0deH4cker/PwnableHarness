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


# These are the other target-specific variables may be defined here
# to override their defaults:
#
# target_CFLAGS:   Command line options passed to CC when compiling
#                  C source files.
#                  Default: empty
#
# target_LDFLAGS:  Command line options passed to LD when linking the
#                  TARGET executable.
#                  Default: empty
#
# target_OFLAGS:   Command line options passed to CC to control the
#                  compiler's optimization settings.
#
# target_NX:       Define this to enable NX aka DEP aka W^X.
#                  Default: empty
#
# target_ASLR:     Define this to enable ASLR.
#                  Default: empty
#
# target_CANARY:   Define this to enable stack protector canaries.
#                  Default: empty
#
# target_RELRO:    Define this to enable full RELRO. This can be set
#                  to "partial" to enable partial RELRO, which is the
#                  default in GCC.
#                  Default: empty
#
# target_BITS:     Either 32 or 64, for deciding the architecture to
#                  build for (i386/amd64).
#                  Default: 32
#
# target_CXXFLAGS: Command line options passed to CXX when compiling
#                  C++ source files.
#                  Default: empty
#
# target_LDLIBS:   Command line options passed to LD when linking the
#                  TARGET executable, used specifically to list the
#                  libraries to link against.
#                  Default: -lpwnableharness$(target_BITS).so
#
# target_SRCS:     List of source files belonging to the TARGET.
#                  Default: Every file matching *.c or *.cpp in the
#                  same directory as Build.mk.
#
# target_CC:       Compiler to use for C sources.
#                  Default: gcc
#
# target_CXX:      Compiler to use for C++ sources.
#                  Default: g++
#
# target_LD:       Linker to use.
#                  Default: target_CXX if there are any C++ source
#                  files in target_SRCS, otherwise target_CC.


# PUBLISH is a list of files within this directory to publish when
# running "make publish". By default, PUBLISH is empty.
#
# Note: make publish will copy every file listed to be published
# to the directory (or symlink) named "publish" in the top level
# of this repo. This feature is useful for publishing files to a web
# server to instantly update challenges.
PUBLISH := $(TARGET) stack0.c

# DOCKER_IMAGE is the name of the docker image to create when
# running "make docker-build".
#
# Note: If DOCKER_IMAGE is not defined, no docker rules will be
# created for this directory.
DOCKER_IMAGE := c0deh4cker/stack0

# DOCKER_BUILD_ARGS is a list of name=value pairs that will be passed
# with --build-arg to docker build when "make docker-build" is run.
# These variables will be usable in a Dockerfile with ARG.
#
# Use the real flag files if they exist.
REAL_FLAG1 := $(patsubst $(DIR)/%,%,$(wildcard $(DIR)/real_flag1.txt))
REAL_FLAG2 := $(patsubst $(DIR)/%,%,$(wildcard $(DIR)/real_flag2.txt))
FLAG1_ARG := $(if $(REAL_FLAG1),FLAG1=$(REAL_FLAG1))
FLAG2_ARG := $(if $(REAL_FLAG2),FLAG2=$(REAL_FLAG2))
DOCKER_BUILD_ARGS := $(FLAG1_ARG) $(FLAG2_ARG)

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

# DOCKER_RUN_ARGS is a list of extra arguments to pass to "docker run".
#
# Mount the root filesystem of the container as read only
DOCKER_RUN_ARGS := --read-only

# DOCKER_ENTRYPOINT_ARGS is a list of arguments to pass to the docker
# container's ENTRYPOINT, which is DOCKER_RUNTIME_NAME.
#DOCKER_ENTRYPOINT_ARGS :=

