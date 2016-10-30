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
# make_rule = $(eval $(_make_rule))
# In this way, _make_rule is recursively expanded in the call context and
# therefore has access to the parameter variables $1, $2, etc that come
# from calling make_rule.
# Because the only difference between the two forms is that the one without
# the leading underscore is eval-ed, when defining such a macro that needs
# to call other macros, call the non-eval-ed version. That prevents double
# evaluation, since otherwise the macro will be evaluated when it is called
# and again when the calling macro is eval-ed.


#####
# generate_target($1: subdirectory, $2: target)
#####
define _generate_target
ifdef VERBOSE
$$(info Generating target rules for $1/$2)
endif

# Ensure that target_BITS has a value, default to 32-bits
ifeq "$$(origin $2_BITS)" "undefined"
$2_BITS := $$($1/BITS)
endif

# Ensure that target_OFLAGS has a value, default to no optimization
ifeq "$$(origin $2_BITS)" "undefined"
$2_OFLAGS := $$($1/OFLAGS)
endif

# Ensure that target_CFLAGS is defined
ifeq "$$(origin $2_CFLAGS)" "undefined"
$2_CFLAGS := $$($1/CFLAGS)
endif

# Ensure that target_CXXFLAGS is defined
ifeq "$$(origin $2_CXXFLAGS)" "undefined"
$2_CXXFLAGS := $$($1/CXXFLAGS)
endif

# Ensure that target_LDFLAGS is defined
ifeq "$$(origin $2_LDFLAGS)" "undefined"
$2_LDFLAGS := $$($1/LDFLAGS)
endif

# Ensure that target_LDLIBS has a value, default to -lpwnableharness(32/64)
ifeq "$$(origin $2_LDLIBS)" "undefined"
# LDLIBS can be set to the string "none" to include no LDLIBS. Otherwise,
# it will default to linking against PwnableHarness if empty.
ifeq "$$($1/LDLIBS)" "none"
$2_LDLIBS :=
else
$2_LDLIBS := $$(or $$($1/LDLIBS),-lpwnableharness$$($2_BITS))
endif
else ifeq "$$($2_LDLIBS)" "none"
$2_LDLIBS :=
endif

# Ensure that target_SRCS has a value, default to searching for all C and
# C++ sources in the same directory as Build.mk.
ifeq "$$(origin $2_SRCS)" "undefined"
$2_SRCS := $$($1/SRCS)
else
# Prefix each item with the project directory
$2_SRCS := $$(addprefix $1/,$$($2_SRCS))
endif

# Ensure that target_OBJS has a value, default to modifying the value of each
# src from target_SRCS into target_BUILD/src.target_BITS.o
# Example: generate_target(proj, target) with main.cpp -> build/proj/main.cpp.32.o
ifeq "$$(origin $2_OBJS)" "undefined"
$2_OBJS := $$(patsubst %,$$(BUILD)/%.$$($2_BITS).o,$$($2_SRCS))
endif

# Ensure that target_DEPS has a value, default to the value of target_OBJS
# but with .o extensions replaced with .d.
ifeq "$$(origin $2_DEPS)" "undefined"
$2_DEPS := $$($2_OBJS:.o=.d)
endif

# Ensure that target_CC has a value, defaulting to gcc
ifeq "$$(origin $2_CC)" "undefined"
$2_CC := $$($1/CC)
endif

# Ensure that target_CXX has a value, defaulting to g++
ifeq "$$(origin $2_CXX)" "undefined"
$2_CXX := $$($1/CXX)
endif

# Ensure that target_LD has a value, defaulting to target_CC unless there are
# C++ sources, in which case target_CXX is used instead
ifeq "$$(origin $2_LD)" "undefined"
$2_LD := $$(or $$($1/LD),$$(if $$(filter %.cpp,$$($2_SRCS)),$$($2_CXX),$$($2_CC)))
endif


# Check if any of the targets in this directory use PwnableHarness
ifneq "$$(filter -lpwnableharness%,$$($2_LDLIBS))" ""
$1/DOCKER_BUILD_DEPS := docker-build[c0deh4cker/pwnableharness]
$1/LINKER_DEPS := libpwnableharness$$($2_BITS).so
else
$1/DOCKER_BUILD_DEPS :=
$1/LINKER_DEPS :=
endif


## Hardening flags

# Ensure that target_RELRO has a value
ifeq "$$(origin $2_RELRO)" "undefined"
$2_RELRO := $$($1/RELRO)
endif

# Ensure that target_CANARY has a value
ifeq "$$(origin $2_CANARY)" "undefined"
$2_CANARY := $$($1/CANARY)
endif

# Ensure that target_NX has a value
ifeq "$$(origin $2_NX)" "undefined"
$2_NX := $$($1/NX)
endif

# Ensure that target_ASLR has a value
ifeq "$$(origin $2_ASLR)" "undefined"
$2_ASLR := $$($1/ASLR)
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
endif

# NX (No Execute) aka DEP (Data Execution Prevention) aka W^X (Write XOR eXecute)
ifndef $2_NX
$2_LDFLAGS := $$($2_LDFLAGS) -z execstack
endif

# ASLR (Address Space Layout Randomization)
ifdef $2_ASLR
$2_CFLAGS := $$($2_CFLAGS) -fPIC
$2_LDFLAGS := $$($2_LDFLAGS) -pie
endif


# Compiler rule for C sources
$$(BUILD)/$1/%.c.$$($2_BITS).o: $1/%.c $$(BUILD)/$1/.dir
	@echo "Compiling $$<"
	$$(_v)$$($2_CC) -m$$($2_BITS) $$(sort -I. -I$1) $$($2_OFLAGS) $$($2_CFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compiler rule for C++ sources
$$(BUILD)/$1/%.cpp.$$($2_BITS).o: $1/%.cpp $$(BUILD)/$1/.dir
	@echo "Compiling $$<"
	$$(_v)$$($2_CC) -m$$($2_BITS) $$(sort -I. -I$1) $$($2_OFLAGS) $$($2_CFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compilation dependency rules
-include $$($2_DEPS)

ifeq "$$(suffix $2)" ".so"
# Linker rule to produce the final target (specialization for shared libraries)
$1/$2: $$($2_OBJS) | $$($1/LINKER_DEPS)
	@echo "Linking shared library $$@"
	$$(_v)$$($2_LD) -m$$($2_BITS) -shared -L. $$($2_LDFLAGS) \
		-o $$@ $$^ $$($2_LDLIBS)

else
# Linker rule to produce the final target (specialization for executables)
$1/$2: $$($2_OBJS) | $$($1/LINKER_DEPS)
	@echo "Linking executable $$@"
	$$(_v)$$($2_LD) -m$$($2_BITS) -L. $$($2_LDFLAGS) \
		-Wl,-rpath,/usr/local/lib,-rpath,`printf "\044"`ORIGIN \
		-o $$@ $$^ $$($2_LDLIBS)

endif #.so

endef #_generate_target
generate_target = $(eval $(call _generate_target,$1,$2))
#####



#####
# include_subdir($1: subdirectory)
#####
define _include_subdir

# Exactly one of these must be defined by Build.mk
TARGET :=
TARGETS :=

# Optional list of files to publish
PUBLISH :=

# These can optionally be defined by Build.mk
DOCKER_IMAGE :=
DOCKER_RUNTIME_NAME :=
DOCKER_BUILD_ARGS :=
DOCKER_PORTS :=
DOCKER_RUN_ARGS :=
DOCKER_ENTRYPOINT_ARGS :=
DOCKER_RUNNABLE :=

# These can optionally be defined to set directory-specific variables
BITS := 32
OFLAGS := -O0
CFLAGS :=
CXXFLAGS :=
LDFLAGS :=
LDLIBS :=
SRCS := $$(foreach ext,c cpp,$$(wildcard $1/*.$$(ext)))
CC := gcc
CXX := g++
LD :=

# Hardening flags
RELRO :=
CANARY :=
NX :=
ASLR :=

# Define DIR for use by Build.mk files
DIR := $1

# First, include the subdirectory's makefile
ifdef VERBOSE
$$(info Including $1/Build.mk)
endif
include $1/Build.mk

# Look for new definition of TARGET/TARGETS
ifdef TARGET
# It's an error to define both TARGET and TARGETS
ifdef TARGETS
$$(error $1/Build.mk defined both TARGET ($$(TARGET)) and TARGETS ($$(TARGETS))!)
endif
$1/TARGETS := $$(TARGET)
else ifdef TARGETS
$1/TARGETS := $$(TARGETS)
else
# It's an error if neither TARGET nor TARGETS are defined
$$(error $1/Build.mk did not define either TARGET or TARGETS!)
endif

# List of target files produced by Build.mk
$1/PRODUCTS := $$(addprefix $1/,$$($1/TARGETS))
$1/PUBLISH := $$(PUBLISH)

# Directory specific variables
$1/BITS := $$(BITS)
$1/OFLAGS := $$(OFLAGS)
$1/CFLAGS := $$(CFLAGS)
$1/CXXFLAGS := $$(CXXFLAGS)
$1/LDFLAGS := $$(LDFLAGS)
$1/LDLIBS := $$(LDLIBS)
$1/SRCS := $$(SRCS)
$1/CC := $$(CC)
$1/CXX := $$(CXX)
$1/LD := $$(LD)

# Directory specific hardening flags
$1/RELRO := $$(RELRO)
$1/CANARY := $$(CANARY)
$1/NX := $$(NX)
$1/ASLR := $$(ASLR)

# Produce target specific variables and build rules
# $$(foreach target,$$($1/TARGETS),$$(info $$(call _generate_target,$1,$$(target))))
$$(foreach target,$$($1/TARGETS),$$(call generate_target,$1,$$(target)))


## Directory specific build rules

# Build rules
all: all[$1]

all[$1]: $$($1/PRODUCTS)

.PHONY: all[$1]

# Publish rules
ifdef $1/PUBLISH
publish: publish[$1]

publish[$1]: $$(addprefix $$(PUB_DIR)/,$$($1/PUBLISH))

$$(addprefix $$(PUB_DIR)/,$$($1/PUBLISH)): $$(PUB_DIR)/%: $1/%
	@echo "Publishing $$*"
	$$(_v)cp $$< $$@

.PHONY: publish[$1]
endif

# Clean rules
clean: clean[$1]

clean[$1]:
	@echo "Removing build directory and products for $1"
	$$(_v)rm -rf $$(patsubst %/.,%,$$(BUILD)/$1) $$($1/PRODUCTS)

.PHONY: clean[$1]

# Automatic creation of build directories
$$(BUILD)/$1/.dir:
	$$(_v)mkdir -p $$(@D) && touch $$@

## Docker variables

# If DOCKER_IMAGE was defined by Build.mk, add docker rules.
ifdef DOCKER_IMAGE
$1/DOCKER_IMAGE := $$(DOCKER_IMAGE)

# Ensure that DIR/DOCKER_RUNTIME_NAME has a value, default to the
# first target in DIR/TARGETS
ifdef DOCKER_RUNTIME_NAME
$1/DOCKER_RUNTIME_NAME := $$(DOCKER_RUNTIME_NAME)
$1/DOCKER_RUNNABLE := true
else
$1/DOCKER_RUNTIME_NAME := $$(firstword $$($1/TARGETS))
endif

# Use DOCKER_PORTS to produce arguments for binding host ports
ifdef DOCKER_PORTS
$1/DOCKER_PORTS := $$(DOCKER_PORTS)
$1/DOCKER_PORT_ARGS := $$(foreach port,$$($1/DOCKER_PORTS),-p $$(port):$$(port))
$1/DOCKER_RUNNABLE := true
endif

# Check if DOCKER_RUN_ARGS was defined
ifdef DOCKER_RUN_ARGS
$1/DOCKER_RUN_ARGS := $$(DOCKER_RUN_ARGS)
$1/DOCKER_RUNNABLE := true
endif

# Check if DOCKER_ENTRYPOINT_ARGS was defined
ifdef DOCKER_ENTRYPOINT_ARGS
$1/DOCKER_ENTRYPOINT_ARGS := $$(DOCKER_ENTRYPOINT_ARGS)
$1/DOCKER_RUNNABLE := true
endif

# Check if DOCKER_RUNNABLE was defined
ifdef DOCKER_RUNNABLE
$1/DOCKER_RUNNABLE = $$(DOCKER_RUNNABLE)
endif

# Ensure that DIR/DOCKER_BUILD_ARGS has a value
ifdef $1/DOCKER_RUNNABLE
$1/DOCKER_BUILD_ARGS := RUNTIME_NAME=$$($1/DOCKER_RUNTIME_NAME)
else
$1/DOCKER_BUILD_ARGS :=
endif
ifdef DOCKER_BUILD_ARGS
$1/DOCKER_BUILD_ARGS := $$($1/DOCKER_BUILD_ARGS) $$(DOCKER_BUILD_ARGS)
endif

# Convert a list of name=value to a list of --build-arg name=value
$1/DOCKER_BUILD_FLAGS := $$(addprefix --build-arg ,$$($1/DOCKER_BUILD_ARGS))


## Docker build rules

# Build a docker image
docker-build: docker-build[$$($1/DOCKER_IMAGE)]

# This only rebuilds the docker image if any of its prerequisites have
# been changed since the last docker build
docker-build[$$($1/DOCKER_IMAGE)]: $$(BUILD)/$1/.docker_build_marker

# Create a marker file to track last docker build time
$$(BUILD)/$1/.docker_build_marker: $$($1/PRODUCTS) | $$($1/DOCKER_BUILD_DEPS)
	@echo "Building docker image $$($1/DOCKER_IMAGE)"
	$$(_v)docker build -t $$($1/DOCKER_IMAGE) $$($1/DOCKER_BUILD_FLAGS) $1 \
		&& touch $$@

# Force build a docker image
docker-rebuild: docker-rebuild[$$($1/DOCKER_IMAGE)]

# This rebuilds the docker image no matter what
docker-rebuild[$$($1/DOCKER_IMAGE)]: | $$($1/PRODUCTS) $$($1/DOCKER_BUILD_DEPS)
	@echo "Rebuilding docker image $$($1/DOCKER_IMAGE)"
	$$(_v)docker build -t $$($1/DOCKER_IMAGE) $$($1/DOCKER_BUILD_FLAGS) $1 \
		&& touch $$(BUILD)/$1/.docker_build_marker


## Docker run rules

ifdef $1/DOCKER_RUNNABLE

# Rule for starting a docker container
docker-start: docker-start[$$($1/DOCKER_RUNTIME_NAME)]

# When starting a container, make sure the docker image is built
# and up to date
docker-start[$$($1/DOCKER_RUNTIME_NAME)]: docker-build[$$($1/DOCKER_IMAGE)]
	@echo "Starting docker container $$($1/DOCKER_RUNTIME_NAME) from image $$($1/DOCKER_IMAGE)"
	$$(_v)docker rm -f $$($1/DOCKER_RUNTIME_NAME) >/dev/null 2>&1 || true
	$$(_v)docker run --restart=unless-stopped --name $$($1/DOCKER_RUNTIME_NAME) -itd \
		-v /etc/localtime:/etc/localtime:ro $$($1/DOCKER_PORT_ARGS) \
		$$($1/DOCKER_RUN_ARGS) $$($1/DOCKER_IMAGE) $$($1/DOCKER_ENTRYPOINT_ARGS)

.PHONY: docker-start[$$($1/DOCKER_RUNTIME_NAME)]

# Rule for restarting a docker container
docker-restart: docker-restart[$$($1/DOCKER_RUNTIME_NAME)]

# Restart a docker container
docker-restart[$$($1/DOCKER_RUNTIME_NAME)]:
	@echo "Restarting docker container $$($1/DOCKER_RUNTIME_NAME)"
	$$(_v)docker restart $$($1/DOCKER_RUNTIME_NAME)

.PHONY: docker-restart[$$($1/DOCKER_RUNTIME_NAME)]

# Rule for stopping a docker container
docker-stop: docker-stop[$$($1/DOCKER_RUNTIME_NAME)]

# Stop the docker container
docker-stop[$$($1/DOCKER_RUNTIME_NAME)]:
	@echo "Stopping docker container $$($1/DOCKER_RUNTIME_NAME)"
	$$(_v)docker stop $$($1/DOCKER_RUNTIME_NAME)

.PHONY: docker-stop[$$($1/DOCKER_RUNTIME_NAME)]

# Rule for removing a docker image and any containers based on it
docker-clean: docker-clean[$$($1/DOCKER_IMAGE)]

# Force remove the container and image
docker-clean[$$($1/DOCKER_IMAGE)]:
	@echo "Cleaning docker image $$($1/DOCKER_IMAGE)"
	$$(_v)docker rm -f $$($1/DOCKER_RUNTIME_NAME) >/dev/null 2>&1 || true
	$$(_v)docker rmi -f $$($1/DOCKER_IMAGE) >/dev/null 2>&1 || true

endif #DOCKER_RUNNABLE

endif #DOCKER_IMAGE


endef #_include_subdir
include_subdir = $(eval $(call _include_subdir,$1))
#####
