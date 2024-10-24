# A directory with a Build.mk file is considered a PwnableHarness project.
#
# A Build.mk file can contain project-specific variables such as TARGET as
# well as target-specific variables like stack0_CFLAGS. A bare minimum Build.mk
# file only needs to define TARGET.
#
# The build system defines the variable DIR to be the path to the directory
# containing Build.mk so it can be used to refer to files. This variable is
# useful because the actual current working directory of the build system is
# always at the top-level of the workspace.
#
# The BUILD_DIR variable is also defined, this time to the build directory for
# this project (typically, `.build/path/to/project` from the workspace root).


## Project-specific variables

# TARGET is the name of the executable to build. If more than one target should
# be built, TARGETS should be set instead of TARGET. TARGET and TARGETS are
# actually handled in exactly the same way by the build system, but they both
# exist for user preference.
#
# Note: It is an error to define both TARGET and TARGETS.
TARGET := stack0


## Target-specific variables: Each of the following variables of the format
# target_VAR are specific to that target. PwnableHarness attempts to resolve
# target-specific variables first by looking for target_VAR, then fallling back
# to VAR (set at the project scope) if not found. This means that setting VAR
# (without the target_ prefix) applies the variable to all targets defined in
# the project, except for those targets with their own target_VAR set.
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
# CFLAGS:          Command line options passed to CC when compiling C sources
#                  Default: empty
#
# CXXFLAGS:        Command line options passed to CXX when compiling C++ sources
#                  Default: empty
#
# ASFLAGS:         Command line options passed to AS when building assembly code
#                  Default: empty
#
# CPPFLAGS:        Command line options passed to CC/CXX/AS, intended to be used
#                    for preprocessor options like -D or -I
#                  DEFAULT: empty
#
# OFLAGS:          Command line options passed to CC/CXX/LD to define custom
#                    optimization flags like -O2, -flto, or -ggdb
#                  Default: -O0
#
# LDFLAGS:         Command line options passed to LD when linking TARGETS, for
#                    both executables and shared libraries
#                  Default: empty
#
# Hardening options: when set to "default", PwnableHarness will not emit any
# compiler/linker arguments related to this setting. This means the compiler's
# default behavior will be used.
#
# NX:              Controls whether the stack is executable or not (W^X).
#                  Choices: 0=off (exec stack), 1=on (noexec stack)
#                  Default: 0
#
# PIE:             Controls whether the TARGET is built with PIE
#                    (as a position-independent executable).
#                  Choices: 0=no pie, 1=pie
#                  Default: 0
#
# ASLR:            Alias for PIE, as enabling PIE enables ASLR for the TARGET.
#
# CANARY:          Controls the use of stack protection canaries.
#                  Choices: 0=none, 1=all
#                  Choices: all, strong, explicit, normal, default, none
#                  Default: none
#
# RELRO:           Controls read-only relocations aka read-only GOT.
#                  Choices: 0=off, 1=now, partial=partial
#                  Default: 0
#
# STRIP:           Define this to strip symbols from the binary.
#                  Choices: 0=don't strip, 1=strip all
#                  Default: 0
#
# DEBUG:           Define this to include debugger symbols.
#                  Choices: 0=no, 1=yes, other=custom option (instead of -ggdb)
#                  Default: 0
#
# BITS:            Whether to build 32-bit or 64-bit binaries.
#                  Choices: 32, 64
#                  Default: 64
BITS := 32
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
# AS:              Assembler to use for building assembly sources (*.S files).
#                  Default: gcc
#
# LD:              Linker to use.
#                  Default: target_CXX if there are any C++ source files in
#                    target_SRCS, otherwise target_CC.
#
# BINTYPE:         Type of binary to build. You can set this to "custom" if you
#                    wish to provide your own linker rule.
#                  Choices: executable, dynamiclib, staticlib, custom
#                  Default: "dynamiclib" if target ends in ".so", "staticlib" if
#                    target ends in ".a", otherwise "executable".
#
# LIBS:            List of dynamic libraries to link against.
#                  Default: empty
#
# NO_EXTRA_*FLAGS: Set this if you don't want PwnableHarness to add of the named
#                    flag type. For example setting NO_EXTRA_LDFLAGS will cause
#                    PwnableHarness to not add any flags related to RELRO, PIE,
#                    RPATH, ASLR, STRIP, etc.
#
# NO_EXTRA_FLAGS:  Set this if you don't want PwnableHarness to add ANY build
#                    flags at all (CPP/C/CXX/AS/O/LD).
#
# NO_UNBUFFERED_STDIO: Set this if you don't want to compile stdio_unbuffer.c
#                        into your target. This will result in stdout and stderr
#                        remaining line-buffered by default, meaning any prints
#                        that don't end in a newline will not be sent over the
#                        connection socket without calling `fflush(stdout)`.
#
# NO_RPATH:        Set this if you don't want PwnableHarness to add the binary's
#                    origin directory to its rpath. This will prevent it from
#                    using any libraries (like libc.so.6) from its directory.
#


# PUBLISH is a list of files to publish when running "make publish", relative to
# the project directory. By default, PUBLISH (and all other PUBLISH_* variables)
# are empty.
#
# Note: "make publish" will copy every file listed to be published to the
# directory named "publish" in the top level of the workspace. This feature is
# useful for publishing files to a web server to instantly update challenges as
# they are rebuilt. The recommended way of doing that is to put symlinks in
# /var/www that point back into the publish directory in your workspace.
PUBLISH := stack0.c

# PUBLISH_BUILD is a list of files to publish when running "make publish",
# relative to this project's build directory.
PUBLISH_BUILD := $(TARGET)

# PUBLISH_TOP is a list of files to publish when running "make publish",
# relative to the top directory of the workspace.
#PUBLISH_TOP := $(DIR)/README.md

# PUBLISH_LIBC is the desired filename used when publishing this challenge's
# libc.so. When this is defined, the exact libc used by the challenge will be
# published to publish/$(DIR)/$(PUBLISH_LIBC). This libc will be copied from
# the Docker image if the challenge is configured to run in Docker, otherwise
# the local system's libc will be copied.
#PUBLISH_LIBC := stack0-libc.so

# PUBLISH_LD is the desired filename used when publish this challenge's
# ld-linux.so. When this is defined, the exact ld-linux.so used by the challenge
# will be published to publish/$(DIR)/$(PUBLISH_LD).
#PUBLISH_LD := $(TARGET)-ld.so

# UBUNTU_VERSION is the numeric or named Ubuntu version which should be
# used as the base image for this challenge. Changing this value will
# change which version of Ubuntu is used both for compiling the challenge
# and for running it.
UBUNTU_VERSION := 16.04

# GLIBC_VERSION is the numeric version number of glibc that is required
# for this challenge. Setting this will select the corresponding version
# of Ubuntu that uses this specific glibc version and use that for compiling
# and running the challenge.
#GLIBC_VERSION := 2.23

# DOCKER_IMAGE is the name of the docker image to create when running
# "make docker-build".
#
# Note: If DOCKER_IMAGE is not defined, no docker rules will be created for this
# directory.
DOCKER_IMAGE := c0deh4cker/stack0

# DOCKER_IMAGE_TAG is the tag to use for this project's Docker image.
# Default: latest
DOCKER_IMAGE_TAG := 2.0

# DOCKER_BUILD_ARGS is a list of name=value pairs that will be passed with
# --build-arg to "docker build" when "make docker-build" is run. These variables
# will be usable in a Dockerfile with ARG.
#DOCKER_BUILD_ARGS :=

# DOCKER_BUILD_DEPS is a list of Makefile dependencies that when changed will
# require the Docker image to be rebuilt. For example, if a challenge provides
# its own Dockerfile which is based on c0deh4cker/pwnableharness and copies the
# file "foo.bin" into the image:
#DOCKER_BUILD_DEPS := $(DIR)/foo.bin

# If DOCKER_RUNNABLE is defined at all, this Docker image will be considered
# runnable.
#
# Note: If any of the variables DOCKER_RUNTIME_NAME, DOCKER_PORTS,
# DOCKER_RUN_ARGS, or DOCKER_ENTRYPOINT_ARGS are defined, then DOCKER_RUNNABLE
# will be assumed to be defined to true.
#DOCKER_RUNNABLE := true

# DOCKER_RUNTIME_NAME is used as the name of the user to create and use for
# handling connections, the executable to run when the Docker container is
# started, and the running container.
#
# Note: If the Docker image is considered to be runnable, then
# DOCKER_RUNTIME_NAME will default to the value of TARGET or the first item in
# TARGETS.
#DOCKER_RUNTIME_NAME := stack0

# DOCKER_PORTS is a list of ports to publish to the host when this Docker
# container is run using "make docker-start".
#
# stack0 listens on port 32101, so bind that to the host.
DOCKER_PORTS := 32101

# DOCKER_TIMELIMIT defines the number of seconds that the target program will
# run before being killed. This is implemented by calling the alarm() syscall
# with this value as the seconds parameter. If this is set to 0 (which is the
# default if left undefined), then there will be no timelimit set.
DOCKER_TIMELIMIT := 30

# DOCKER_CPULIMIT defines the maximum allowed CPU usage by this challenge's
# Docker container. This is a fractional number of CPUs the container may
# use, so the default of 0.5 means the challenge may only use half of a single
# virtual CPU core.
#DOCKER_CPULIMIT := 0.5

# DOCKER_MEMLIMIT defines the maximum amount of RAM that may be used by this
# challenge's Docker container. The container is disallowed from using swap
# memory, so this value is the total amount of memory that may be used. A suffix
# like "m" allows using different units.
#DOCKER_MEMLIMIT := 500m

# DOCKER_RUN_ARGS is a list of extra arguments to pass to "docker run".
#DOCKER_RUN_ARGS := --env SOMETHING=42

# DOCKER_WRITEABLE is used to make the Docker container's filesystem writeable.
# Without this, the Docker container's filesystem will be read-only.
#DOCKER_WRITEABLE := true

# DOCKER_ENTRYPOINT_ARGS is a list of arguments to pass to the Docker
# container's ENTRYPOINT. This is only useful for custom Dockerfiles.
#DOCKER_ENTRYPOINT_ARGS :=

# DOCKER_PWNABLESERVER_ARGS is a list of additional arguments to pass to
# pwnableserver when it is launched in the Docker container.
#
#DOCKER_PWNABLESERVER_ARGS := --inject my_preload_library.so

# DOCKER_CHALLENGE_ARGS is a list of arguments to pass to the challenge when it
# is run in Docker under pwnableserver.
#DOCKER_CHALLENGE_ARGS :=

# DEPLOY_COMMAND is a string containing a command that should be run during
# `make deploy` from the project directory.
#DEPLOY_COMMAND := echo "[DEPLOY] Dockerfile is: `cat Dockerfile`"

# DEPLOY_DEPS is a list of Makefile dependencies that should be up to date
# before the DEPLOY_COMMAND is run.
#DEPLOY_DEPS := $(DIR)/flag1.txt

# CLEAN is the name of a Makefile rule that should be run when this project
# should be cleaned. By default, the project's TARGETS and each target's objs
# directories will be deleted on `make clean-one[PROJECT]`. Anything else should
# be manually cleaned up by adding a custom clean rule and storing the name of
# this rule in CLEAN.
#CLEAN := my-clean
#my-clean:
#    rm -f $(BUILD_DIR)/foo.zip
