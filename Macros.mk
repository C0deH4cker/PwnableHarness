# Naming convention for macros declared here:
#
# Macros named with a leading underscore must be eval-ed after calling them,
# whereas those without a leading underscore do not. Whenever a macro that
# requires eval-ing is defined, both macros with and without the leading
# underscore are defined, where the one without is defined as eval-ing the
# underscore-prefixed version.
#
# For example, macro named _make_rule must be called using:
# $(eval $(call _make_rule,args...))
# whereas a macro named make_rule must be called using:
# $(call make_rule,args)
# Also, when both forms are present, make_rule is defined like so:
# make_rule = $(eval $(call _make_rule,args...))
# In this way, _make_rule is recursively expanded in the call context and
# therefore has access to the parameter variables $1, $2, etc that come
# from calling make_rule.
#
# Because the only difference between the two forms is that the one without
# the leading underscore is eval-ed, when defining such a macro that needs
# to call other macros, call the non-eval-ed version. That prevents double
# evaluation, since otherwise the macro will be evaluated when it is called
# and again when the calling macro is eval-ed.


#####
# generate_target($1: subdirectory, $2: target)
#
# Generate the rules to build the given target contained within the given directory.
#####
define _generate_target
ifdef MKDEBUG
$$(info Generating target rules for $1+$2)
endif

# Ensure that target_BITS has a value, default to 32-bits
ifeq "$$(origin $2_BITS)" "undefined"
$2_BITS := $$($1+BITS)
endif

# Ensure that target_OFLAGS has a value, default to no optimization
ifeq "$$(origin $2_OFLAGS)" "undefined"
$2_OFLAGS := $$($1+OFLAGS)
endif

# Ensure that target_CFLAGS is defined
ifeq "$$(origin $2_CFLAGS)" "undefined"
$2_CFLAGS := $$($1+CFLAGS)
endif

# Ensure that target_CXXFLAGS is defined
ifeq "$$(origin $2_CXXFLAGS)" "undefined"
$2_CXXFLAGS := $$($1+CXXFLAGS)
endif

# Ensure that target_LDFLAGS is defined
ifeq "$$(origin $2_LDFLAGS)" "undefined"
$2_LDFLAGS := $$($1+LDFLAGS)
endif

# Ensure that target_SRCS has a value, default to searching for all C and
# C++ sources in the same directory as Build.mk.
ifeq "$$(origin $2_SRCS)" "undefined"
$2_SRCS := $$($1+SRCS)
else
# Prefix each item with the project directory
$2_SRCS := $$(addprefix $1/,$$($2_SRCS))
endif

# Ensure that target_OBJS has a value, default to modifying the value of each
# src from target_SRCS into target_BUILD/src.o
# Example: generate_target(proj, target) with main.cpp -> build/proj/target_objs/main.cpp.o
ifeq "$$(origin $2_OBJS)" "undefined"
$2_OBJS := $$(patsubst $1/%,$$(BUILD)/$1/$2_objs/%.o,$$($2_SRCS))
endif

# Ensure that target_DEPS has a value, default to the value of target_OBJS
# but with .o extensions replaced with .d.
ifeq "$$(origin $2_DEPS)" "undefined"
$2_DEPS := $$($2_OBJS:.o=.d)
endif

# Ensure that target_CC has a value, defaulting to gcc
ifeq "$$(origin $2_CC)" "undefined"
$2_CC := $$($1+CC)
endif

# Ensure that target_CXX has a value, defaulting to g++
ifeq "$$(origin $2_CXX)" "undefined"
$2_CXX := $$($1+CXX)
endif

# Ensure that target_LD has a value, defaulting to target_CC unless there are
# C++ sources, in which case target_CXX is used instead
ifeq "$$(origin $2_LD)" "undefined"
$2_LD := $$(or $$($1+LD),$$(if $$(filter %.cpp,$$($2_SRCS)),$$($2_CXX),$$($2_CC)))
endif

# Ensure that target_BINTYPE has a value, defaulting to "dynamiclib" if target
# name ends in ".so" otherwise "executable".
ifeq "$$(origin $2_BINTYPE)" "undefined"
ifdef $1+BINTYPE
$2_BINTYPE := $$($1+BINTYPE)
else ifeq "$$(suffix $2)" ".so"
$2_BINTYPE := dynamiclib
else #BINTYPE & suffix .so
$2_BINTYPE := executable
endif #BINTYPE & suffix .so
endif #target_BINTYPE undefined

# Ensure that target_LIBS has a value
ifeq "$$(origin $2_LIBS)" "undefined"
$2_LIBS := $$($1+LIBS)
endif #target_LIBS undefined

# Ensure that target_USE_LIBPWNABLEHARNESS has a value
ifeq "$$(origin $2_USE_LIBPWNABLEHARNESS)" "undefined"
$2_USE_LIBPWNABLEHARNESS := $$($1+USE_LIBPWNABLEHARNESS)
endif

# Add dependency on libpwnableharness[32|64] if requested
ifdef $2_USE_LIBPWNABLEHARNESS
$2_ALLLIBS := $$($2_LIBS) libpwnableharness$$($2_BITS).so
else
$2_ALLLIBS := $$($2_LIBS)
endif

# If additional shared libraries should be linked, allow loading them from the
# executable's directory and from /usr/local/lib
ifdef $2_ALLLIBS
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-rpath,/usr/local/lib,-rpath,`printf "\044"`ORIGIN
endif #target_ALLLIBS

# Convert a list of dynamic library names into linker arguments
$2_LIBPATHS := $$(sort $$(dir $$($2_ALLLIBS)))
$2_LDPATHARGS := $$(addprefix -L,$$($2_LIBPATHS))
$2_LDLIBS := $$(patsubst lib%.so,-l%,$$(notdir $$($2_ALLLIBS)))


## Hardening flags

# Ensure that target_RELRO has a value
ifeq "$$(origin $2_RELRO)" "undefined"
$2_RELRO := $$($1+RELRO)
endif

# Ensure that target_CANARY has a value
ifeq "$$(origin $2_CANARY)" "undefined"
$2_CANARY := $$($1+CANARY)
endif

# Ensure that target_NX has a value
ifeq "$$(origin $2_NX)" "undefined"
$2_NX := $$($1+NX)
endif

# Ensure that target_ASLR has a value
ifeq "$$(origin $2_ASLR)" "undefined"
$2_ASLR := $$($1+ASLR)
endif

# Ensure that target_STRIP has a value
ifeq "$$(origin $2_STRIP)" "undefined"
$2_STRIP := $$($1+STRIP)
endif

# Ensure that target_DEBUG has a value
ifeq "$$(origin $2_DEBUG)" "undefined"
$2_DEBUG := $$($1+DEBUG)
endif


## Apply hardening flags

# RELRO (Read-only relocations)
ifdef $2_RELRO
ifneq "$$($2_RELRO)" "partial"
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-z,relro,-z,now
endif #partial
else #RELRO
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-z,norelro
endif #RELRO

# Stack canary
ifndef $2_CANARY
$2_CFLAGS := $$($2_CFLAGS) -fno-stack-protector
$2_CXXFLAGS := $$($2_CXXFLAGS) -fno-stack-protector
endif

# NX (No Execute) aka DEP (Data Execution Prevention) aka W^X (Write XOR eXecute)
ifndef $2_NX
$2_LDFLAGS := $$($2_LDFLAGS) -z execstack
endif

# ASLR (Address Space Layout Randomization)
ifdef $2_ASLR
$2_CFLAGS := $$($2_CFLAGS) -fPIC
$2_CXXFLAGS := $$($2_CXXFLAGS) -fPIC
ifeq "$$($2_BINTYPE)" "executable"
$2_LDFLAGS := $$($2_LDFLAGS) -pie
endif #executable
else #ASLR
ifeq "$$($2_BINTYPE)" "executable"
$2_LDFLAGS := $$($2_LDFLAGS) -no-pie
endif #executable
endif #ASLR

# Strip symbols
ifdef $2_STRIP
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-s
endif

# Debug symbols
ifdef $2_DEBUG
$2_CFLAGS := $$($2_CFLAGS) -ggdb -DDEBUG=1 -UNDEBUG
$2_CXXFLAGS := $$($2_CXXFLAGS) -ggdb -DDEBUG=1 -UNDEBUG
$2_LDFLAGS := $$($2_LDFLAGS) -ggdb
else #DEBUG
$2_CFLAGS := $$($2_CFLAGS) -DNDEBUG=1
$2_CXXFLAGS := $$($2_CXXFLAGS) -DNDEBUG=1
endif #DEBUG


# Rebuild all build products when the Build.mk is modified
$$($2_OBJS): $1/Build.mk
$1/$2: $1/Build.mk

# Compiler rule for C sources
$$(filter %.c.o,$$($2_OBJS)): $$(BUILD)/$1/$2_objs/%.c.o: $1/%.c $$(BUILD)/$1/$2_objs/.dir
	$$(_V)echo "Compiling $$<"
	$$(_v)$$($2_CC) -m$$($2_BITS) $$(sort -I. -I$1) $$($2_OFLAGS) $$($2_CFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compiler rule for C++ sources
$$(filter %.cpp.o,$$($2_OBJS)): $$(BUILD)/$1/$2_objs/%.cpp.o: $1/%.cpp $$(BUILD)/$1/$2_objs/.dir
	$$(_V)echo "Compiling $$<"
	$$(_v)$$($2_CXX) -m$$($2_BITS) $$(sort -I. -I$1) $$($2_OFLAGS) $$($2_CXXFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compilation dependency rules
-include $$($2_DEPS)

ifeq "$$($2_BINTYPE)" "dynamiclib"
# Linker rule to produce the final target (specialization for shared libraries)
$1/$2: $$($2_OBJS) $$($2_ALLLIBS)
	$$(_V)echo "Linking shared library $$@"
	$$(_v)$$($2_LD) -m$$($2_BITS) -shared $$($2_LDPATHARGS) $$($2_LDFLAGS) \
		-o $$@ $$($2_OBJS) $$($2_LDLIBS)

else ifeq "$$($2_BINTYPE)" "executable"
# Linker rule to produce the final target (specialization for executables)
$1/$2: $$($2_OBJS) $$($2_ALLLIBS)
	$$(_V)echo "Linking executable $$@"
	$$(_v)$$($2_LD) -m$$($2_BITS) $$($2_LDPATHARGS) $$($2_LDFLAGS) \
		-o $$@ $$($2_OBJS) $$($2_LDLIBS)

else #dynamiclib & executable

# Assume that the user will provide their own linker rule here
ifdef MKDEBUG
$$(info Not generating a linker rule for $1/$2 because its BINTYPE is "$$($2_BINTYPE)")
endif #MKDEBUG

endif #dynamiclib & executable

endef #_generate_target
generate_target = $(eval $(call _generate_target,$1,$2))
#####




#####
# docker_compose($1: project directory, $2: challenge name)
#
# Rules for deploying a docker-compose project
#####
define _docker_compose

# make docker-build
docker-build: docker-build[$2]

docker-build[$2]: docker-rebuild[$2]

.PHONY: docker-build[$2]


# make docker-rebuild
docker-rebuild: docker-rebuild[$2]

docker-rebuild[$2]:
	$$(_V)echo "Building $2 images with docker-compose"
	$$(_v)cd $1 && docker-compose build


# make docker-start
docker-start: docker-start[$2]

docker-start[$2]:
	$$(_V)echo "Starting $2 containers with docker-compose"
	$$(_v)cd $1 && docker-compose up -d


# make docker-restart
docker-restart: docker-restart[$2]

docker-restart[$2]:
	$$(_V)echo "Restarting $2 containers with docker-compose"
	$$(_v)cd $1 && docker-compose restart


# make docker-stop
docker-stop: docker-stop[$2]

docker-stop[$2]:
	$$(_V)echo "Stopping $2 containers with docker-compose"
	$$(_v)cd $1 && docker-compose down


# make docker-clean
docker-clean: docker-clean[$2]

docker-clean[$2]:
	$$(_V)echo "Removing $2 containers with docker-compose"
	$$(_v)cd $1 && docker-compose rm --stop

endef #_docker_compose
docker_compose = $(eval $(call _docker_compose,$1,$2))
#####




#####
# include_subdir($1: subdirectory)
#
# Check for a Build.mk file in the given directory. If one exists, include it and
# automatically generate all target dependencies and rules to build the products.
#####
define _include_subdir

ifneq "$$(wildcard $1/Build.mk)" ""

# Append project directory to the list of discovered projects
PROJECT_LIST := $$(PROJECT_LIST) $1

# Exactly one of these must be defined by Build.mk
TARGET :=
TARGETS :=

# For advanced users that want to define custom build rules for a directory
PRODUCTS :=

# Optional list of files to publish
PUBLISH :=
PUBLISH_LIBC :=

# Deployment
DEPLOY_COMMAND :=
DEPLOY_DEPS :=

# Optional CTF flag management
FLAG :=
FLAG_FILE := $(or $(wildcard $1/real_flag.txt),$(wildcard $1/flag.txt))
FLAG_DST := flag.txt

# These can optionally be defined by Build.mk for Docker management
DOCKERFILE :=
DOCKER_IMAGE :=
DOCKER_IMAGE_CUSTOM :=
DOCKER_RUNTIME_NAME :=
DOCKER_BUILD_ARGS :=
DOCKER_BUILD_DEPS :=
DOCKER_PORTS :=
DOCKER_PORT_ARGS :=
DOCKER_RUN_ARGS :=
DOCKER_ENTRYPOINT_ARGS :=
DOCKER_RUNNABLE :=
DOCKER_TIMELIMIT := 0
DOCKER_WRITEABLE :=

# These can optionally be defined to set directory-specific variables
BITS := 32
OFLAGS := -O0
CFLAGS :=
CXXFLAGS :=
LDFLAGS :=
SRCS := $$(patsubst $1/%,%,$$(foreach ext,c cpp,$$(wildcard $1/*.$$(ext))))
CC := gcc
CXX := g++
LD :=
BINTYPE :=
LIBS :=
USE_LIBPWNABLEHARNESS :=

# Hardening flags
RELRO :=
CANARY :=
NX :=
ASLR :=
STRIP :=
DEBUG :=

# Define DIR for use by Build.mk files
DIR := $1

# First, include the subdirectory's makefile
ifdef MKDEBUG
$$(info Including $1/Build.mk)
endif
include $1/Build.mk

# Look for new definition of TARGET/TARGETS
ifdef TARGET
# It's an error to define both TARGET and TARGETS
ifdef TARGETS
$$(error $1/Build.mk defined both TARGET ($$(TARGET)) and TARGETS ($$(TARGETS))!)
endif
$1+TARGETS := $$(TARGET)
else ifdef TARGETS
$1+TARGETS := $$(TARGETS)
else
# Neither TARGET nor TARGETS are defined. This Build.mk file may still be useful for deployment
ifdef MKDEBUG
$$(warning $1/Build.mk defines no targets.)
endif
$1+TARGETS :=
endif

# List of target files produced by Build.mk
$1+PRODUCTS := $$(PRODUCTS)
ifndef $1+PRODUCTS
$1+PRODUCTS := $$(addprefix $1/,$$($1+TARGETS))
endif

# Publishing
$1+PUBLISH := $$(PUBLISH)
$1+PUBLISH_LIBC := $$(PUBLISH_LIBC)
$1+PUBLISH_DST := $$(addprefix $$(PUB_DIR)/$1/,$$($1+PUBLISH))

# Deployment
$1+DEPLOY_COMMAND := $$(DEPLOY_COMMAND)
$1+DEPLOY_DEPS := $$(DEPLOY_DEPS)

# CTF flag management
$1+FLAG := $$(FLAG)
$1+FLAG_FILE := $$(FLAG_FILE)
$1+FLAG_DST := $$(FLAG_DST)

# Docker variables
$1+DOCKERFILE := $$(DOCKERFILE)
$1+DOCKER_IMAGE := $$(DOCKER_IMAGE)
$1+DOCKER_IMAGE_CUSTOM := $$(DOCKER_IMAGE_CUSTOM)
$1+DOCKER_RUNTIME_NAME := $$(DOCKER_RUNTIME_NAME)
$1+DOCKER_BUILD_ARGS := $$(DOCKER_BUILD_ARGS)
$1+DOCKER_BUILD_DEPS := $$(DOCKER_BUILD_DEPS)
$1+DOCKER_PORTS := $$(DOCKER_PORTS)
$1+DOCKER_PORT_ARGS := $$(DOCKER_PORT_ARGS)
$1+DOCKER_RUN_ARGS := $$(DOCKER_RUN_ARGS)
$1+DOCKER_ENTRYPOINT_ARGS := $$(DOCKER_ENTRYPOINT_ARGS)
$1+DOCKER_RUNNABLE := $$(DOCKER_RUNNABLE)
$1+DOCKER_TIMELIMIT := $$(DOCKER_TIMELIMIT)
$1+DOCKER_WRITEABLE := $$(DOCKER_WRITEABLE)
$1+DOCKER_COMPOSE := $$(wildcard $1/docker-compose.yml)

# Directory specific variables
$1+BITS := $$(BITS)
$1+OFLAGS := $$(OFLAGS)
$1+CFLAGS := $$(CFLAGS)
$1+CXXFLAGS := $$(CXXFLAGS)
$1+LDFLAGS := $$(LDFLAGS)
$1+SRCS := $$(addprefix $1/,$$(SRCS))
$1+CC := $$(CC)
$1+CXX := $$(CXX)
$1+LD := $$(LD)
$1+BINTYPE := $$(BINTYPE)
$1+LIBS := $$(LIBS)
$1+USE_LIBPWNABLEHARNESS := $$(USE_LIBPWNABLEHARNESS)

# Directory specific hardening flags
$1+RELRO := $$(RELRO)
$1+CANARY := $$(CANARY)
$1+NX := $$(NX)
$1+ASLR := $$(ASLR)
$1+STRIP := $$(STRIP)
$1+DEBUG := $$(DEBUG)

# Produce target specific variables and build rules
# $$(foreach target,$$($1+TARGETS),$$(info $$(call _generate_target,$1,$$(target))))
$$(foreach target,$$($1+TARGETS),$$(call generate_target,$1,$$(target)))


## Directory specific build rules

# Build rules
all: all[$1]

all[$1]: $$($1+PRODUCTS)

.PHONY: all[$1]

# Publish rules
ifdef $1+PUBLISH

publish: publish[$1]

publish[$1]: $$($1+PUBLISH_DST)

$$($1+PUBLISH_DST): $$(PUB_DIR)/$1/%: $1/%
	$$(_V)echo "Publishing $1/$$*"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

.PHONY: publish[$1]

endif #$1+PUBLISH

# Deploy rules
ifdef $1+DEPLOY_COMMAND

deploy: deploy[$1]

deploy[$1]: $$($1+DEPLOY_DEPS)
	$$(_V)echo "Deploying $1"
	$$(_v)cd $1 && $$($1+DEPLOY_COMMAND)

.PHONY: deploy[$1]

endif #$1+DEPLOY_COMMAND

# Clean rules
clean: clean[$1]

clean[$1]:
	$$(_V)echo "Removing build directory and products for $1"
	$$(_v)rm -rf $$(patsubst %/.,%,$$(BUILD)/$1) $$($1+PRODUCTS)

.PHONY: clean[$1]

## Docker variables

ifdef $1+DOCKER_COMPOSE
$$(call docker_compose,$1,$$(notdir $1))
endif #DOCKER_COMPOSE

# If DOCKER_IMAGE was defined by Build.mk, add docker rules.
ifdef $1+DOCKER_IMAGE

# Check if there is a Dockerfile in this directory
ifndef $1+DOCKERFILE
$1+DOCKERFILE := $$(wildcard $1/Dockerfile)

# If $1+Dockerfile doesn't exist, we will use the default Dockerfile
ifndef $1+DOCKERFILE
$1+DOCKERFILE := default.Dockerfile
endif #exists DIR+Dockerfile
endif #DOCKERFILE

# If the Dockerfile to use isn't in the project directory, add a rule to copy it there
ifneq "$$(dir $$($1+DOCKERFILE))" "$1/"

$1/$$(notdir $$($1+DOCKERFILE)): $$($1+DOCKERFILE)
	$$(_V)echo 'Copying $$< to $$@'
	$$(_v)cp $$< $$@

endif #dir DOCKERFILE

# If the Dockerfile doesn't have the standard name, add an argument telling
# docker build which Dockerfile to use
ifneq "$$($1+DOCKERFILE)" "$1+Dockerfile"
$1+DOCKER_BUILD_ARGS := -f $1/$$(notdir $$($1+DOCKERFILE)) $$($1+DOCKER_BUILD_ARGS)
endif #Dockerfile

# Docker images depend on the base PwnableHarness Docker image
ifneq "$$($1+DOCKER_IMAGE)" "c0deh4cker/pwnableharness"
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) docker-build[c0deh4cker/pwnableharness]
endif
endif

# Add the Dockerfile as a dependency for the docker-build target
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) $1/$$(notdir $$($1+DOCKERFILE))

# The Build.mk file is a dependency for the docker-build target
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) $1/Build.mk

# Ensure that DIR+DOCKER_RUNTIME_NAME has a value, default to the
# first target in DIR+TARGETS, or if that's not defined, the name of the image
ifdef $1+DOCKER_RUNTIME_NAME
$1+DOCKER_RUNNABLE := true
else
$1+DOCKER_RUNTIME_NAME := $$(or $$(firstword $$($1+TARGETS)),$$($1+DOCKER_IMAGE))
endif

# Use DOCKER_PORTS to produce arguments for binding host ports
ifdef $1+DOCKER_PORTS
$1+DOCKER_PORT_ARGS := $$(foreach port,$$($1+DOCKER_PORTS),-p $$(port):$$(port))
$1+DOCKER_RUNNABLE := true

ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "PORT=$$(firstword $$($1+DOCKER_PORTS))" --build-arg "TIMELIMIT=$$($1+DOCKER_TIMELIMIT)"
endif #DOCKER_IMAGE_CUSTOM
endif #DOCKDER_PORTS

# Check if DOCKER_RUN_ARGS was defined
ifdef $1+DOCKER_RUN_ARGS
$1+DOCKER_RUNNABLE := true
endif

# Add flag if the Docker container's filesystem should be read-only
ifndef $1+DOCKER_WRITEABLE
ifeq "$$(filter --read-only,$$($1+DOCKER_RUN_ARGS))" ""
$1+DOCKER_RUN_ARGS := $$($1+DOCKER_RUN_ARGS) --read-only
endif
endif

# Check if DOCKER_ENTRYPOINT_ARGS was defined
ifdef $1+DOCKER_ENTRYPOINT_ARGS
$1+DOCKER_RUNNABLE := true
endif

# Append the RUNTIME_NAME to the list of docker build arg
ifdef $1+DOCKER_RUNNABLE
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "RUNTIME_NAME=$$($1+DOCKER_RUNTIME_NAME)"
endif
endif

# Automatic flag support is only provided for non-custom Docker images
ifndef $1+DOCKER_IMAGE_CUSTOM

# Adding the flag to the docker image
$1+HAS_FLAG := true
ifdef $1+FLAG_FILE
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "FLAG=`cat $$($1+FLAG_FILE)`"
else #FLAG_FILE
ifdef $1+FLAG
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "FLAG=$$($1+FLAG)"
else #FLAG
$1+HAS_FLAG :=
endif #FLAG
endif #FLAG_FILE

# Adding flag destination if the project includes a flag
ifdef $1+HAS_FLAG
ifdef $1+FLAG_DST
ifdef MKDEBUG
$$(info Placing flag for docker image $$($1+DOCKER_IMAGE) in $$($1+FLAG_DST))
endif #MKDEBUG

$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "FLAG_DST=$$($1+FLAG_DST)"
endif #FLAG_DST
endif #HAS_FLAG

endif #DOCKER_IMAGE_CUSTOM

# Assume that DOCKER_BUILD_ARGS is already formatted as a list of "--build-arg name=value"
$1+DOCKER_BUILD_FLAGS := $$($1+DOCKER_BUILD_ARGS)


## Docker build rules

# Build a docker image
docker-build: docker-build[$$($1+DOCKER_IMAGE)]

# This only rebuilds the docker image if any of its prerequisites have
# been changed since the last docker build
docker-build[$$($1+DOCKER_IMAGE)]: $$(BUILD)/$1/.docker_build_marker

# Create a marker file to track last docker build time
$$(BUILD)/$1/.docker_build_marker: $$($1+PRODUCTS) $$($1+DOCKER_BUILD_DEPS) $$(BUILD)/$1/.dir
	$$(_V)echo "Building docker image $$($1+DOCKER_IMAGE)"
	$$(_v)docker build -t $$($1+DOCKER_IMAGE) $$($1+DOCKER_BUILD_FLAGS) $1 \
		&& touch $$@

# Force build a docker image
docker-rebuild: docker-rebuild[$$($1+DOCKER_IMAGE)]

# This rebuilds the docker image no matter what
docker-rebuild[$$($1+DOCKER_IMAGE)]: | $$($1+PRODUCTS) $$($1+DOCKER_BUILD_DEPS) $$(BUILD)/$1/.dir
	$$(_V)echo "Rebuilding docker image $$($1+DOCKER_IMAGE)"
	$$(_v)docker build -t $$($1+DOCKER_IMAGE) $$($1+DOCKER_BUILD_FLAGS) $1 \
		&& touch $$(BUILD)/$1/.docker_build_marker


## Docker run rules

ifdef $1+DOCKER_RUNNABLE

# Rule for starting a docker container
docker-start: docker-start[$$($1+DOCKER_RUNTIME_NAME)]

# When starting a container, make sure the docker image is built
# and up to date
docker-start[$$($1+DOCKER_RUNTIME_NAME)]: docker-build[$$($1+DOCKER_IMAGE)]
	$$(_V)echo "Starting docker container $$($1+DOCKER_RUNTIME_NAME) from image $$($1+DOCKER_IMAGE)"
	$$(_v)docker rm -f $$($1+DOCKER_RUNTIME_NAME) >/dev/null 2>&1 || true
	$$(_v)docker run -itd --restart=unless-stopped --name $$($1+DOCKER_RUNTIME_NAME) \
		-v /etc/localtime:/etc/localtime:ro $$($1+DOCKER_PORT_ARGS) \
		$$($1+DOCKER_RUN_ARGS) $$($1+DOCKER_IMAGE) $$($1+DOCKER_ENTRYPOINT_ARGS)

.PHONY: docker-start[$$($1+DOCKER_RUNTIME_NAME)]

# Rule for restarting a docker container
docker-restart: docker-restart[$$($1+DOCKER_RUNTIME_NAME)]

# Restart a docker container
docker-restart[$$($1+DOCKER_RUNTIME_NAME)]:
	$$(_V)echo "Restarting docker container $$($1+DOCKER_RUNTIME_NAME)"
	$$(_v)docker restart $$($1+DOCKER_RUNTIME_NAME)

.PHONY: docker-restart[$$($1+DOCKER_RUNTIME_NAME)]

# Rule for stopping a docker container
docker-stop: docker-stop[$$($1+DOCKER_RUNTIME_NAME)]

# Stop the docker container
docker-stop[$$($1+DOCKER_RUNTIME_NAME)]:
	$$(_V)echo "Stopping docker container $$($1+DOCKER_RUNTIME_NAME)"
	$$(_v)docker stop $$($1+DOCKER_RUNTIME_NAME)

.PHONY: docker-stop[$$($1+DOCKER_RUNTIME_NAME)]

# Rule for removing a docker image and any containers based on it
docker-clean: docker-clean[$$($1+DOCKER_IMAGE)]

# Force remove the container and image
docker-clean[$$($1+DOCKER_IMAGE)]:
	$$(_V)echo "Cleaning docker image $$($1+DOCKER_IMAGE)"
	$$(_v)docker rm -f $$($1+DOCKER_RUNTIME_NAME) >/dev/null 2>&1 || true
	$$(_v)docker rmi -f $$($1+DOCKER_IMAGE) >/dev/null 2>&1 || true

endif #DOCKER_RUNNABLE

endif #DOCKER_IMAGE


# Publish libc for the challenge
ifdef $1+PUBLISH_LIBC

# Decide whether to grab the 32-bit or 64-bit libc
ifeq "$$($1+BITS)" "32"
$1+LIBC_PATH := /lib/i386-linux-gnu/libc.so.6
else
$1+LIBC_PATH := /lib/x86_64-linux-gnu/libc.so.6
endif

publish[$1]: $$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC)

# Copy the libc from Docker only if the challenge is configured to run in Docker
ifdef $1+DOCKER_RUNNABLE
# If the challenge runs within Docker, copy the libc from the docker image
$$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC): docker-build[$$($1+DOCKER_IMAGE)] | $$(PUB_DIR)/$1/.dir
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LIBC) from docker image $$($1+DOCKER_IMAGE):$$($1+LIBC_PATH)"
	$$(_v)mkdir -p $$(@D) && docker run --rm --entrypoint /bin/cat $$($1+DOCKER_IMAGE) $$($1+LIBC_PATH) > $$@

else #DOCKER_RUNNABLE
# If the challenge doesn't run in Docker, copy the system's libc
$$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC): $$($1+LIBC_PATH)
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LIBC) from $$<"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

endif #DOCKER_RUNNABLE
endif #PUBLISH_LIBC
endif #exists DIR/Build.mk

endef #_include_subdir
include_subdir = $(eval $(call _include_subdir,$1))
#####


#####
# recurse_subdir($1: subdirectory)
#
# Perform a depth-first recursion through the given directory including all Build.mk files found.
#####
define _recurse_subdir

# Include this directory's Build.mk file if it exists
$$(call include_subdir,$1)

# Make a list of all items in this directory that are directories and strip the trailing "/"
$1+SUBDIRS := $$(patsubst %/,%,$$(dir $$(wildcard $1/*/)))

# Remove current directory and blacklisted items from the list of subdirectories
$1+SUBDIRS := $$(filter-out $1 %.disabled $$(addprefix %/,$$(RECURSION_BLACKLIST)),$$($1+SUBDIRS))

# Strip off the leading "./" in the subdirectory names
$1+SUBDIRS := $$(patsubst ./%,%,$$($1+SUBDIRS))

ifdef MKDEBUG
ifdef $1+SUBDIRS
$$(info Recursing from $1 into $$($1+SUBDIRS))
endif
endif

# Recurse into each subdirectory
$$(foreach sd,$$($1+SUBDIRS),$$(call recurse_subdir,$$(sd)))

# If there's an After.mk present, include it after the Build.mk for the project and all
# descendent projects have been included.
ifneq "$$(wildcard $1/After.mk)" ""
DIR := $1
include $1/After.mk
endif

endef #_recurse_subdir
recurse_subdir = $(eval $(call _recurse_subdir,$1))
#####
