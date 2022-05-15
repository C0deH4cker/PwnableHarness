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


# Set defaults
ifndef DEFAULT_BITS
DEFAULT_BITS := 64
endif

ifndef DEFAULT_OFLAGS
DEFAULT_OFLAGS := -O0
endif

ifndef DEFAULT_CFLAGS
DEFAULT_CFLAGS :=
endif

ifndef DEFAULT_CXXFLAGS
DEFAULT_CXXFLAGS :=
endif

ifndef DEFAULT_LDFLAGS
DEFAULT_LDFLAGS :=
endif

ifndef DEFAULT_CC
DEFAULT_CC := gcc
endif

ifndef DEFAULT_CXX
DEFAULT_CXX := g++
endif

ifndef DEFAULT_LD
DEFAULT_LD :=
endif

ifndef DEFAULT_AR
DEFAULT_AR := ar
endif


#####
# generate_target($1: subdirectory, $2: target)
#
# Generate the rules to build the given target contained within the given directory.
#####
define _generate_target
ifdef MKDEBUG
$$(info Generating target rules for $1+$2)
endif

# Product path
ifeq "$$(origin $2_PRODUCT)" "undefined"
$2_PRODUCT := $$(or $$($1+PRODUCT),$$($1+BUILD)/$2)
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
$2_OBJS := $$(patsubst $1/%,$$($1+BUILD)/$2_objs/%.o,$$($2_SRCS))
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

# Ensure that target_AR has a value
ifeq "$$(origin $2_AR)" "undefined"
$2_AR := $$($1+AR)
endif

# Ensure that target_BINTYPE has a value, defaulting to "dynamiclib" if target
# name ends in ".so" otherwise "executable".
ifeq "$$(origin $2_BINTYPE)" "undefined"
ifdef $1+BINTYPE
$2_BINTYPE := $$($1+BINTYPE)
else ifeq "$$(suffix $2)" ".so"
$2_BINTYPE := dynamiclib
else ifeq "$$(suffix $2)" ".a"
$2_BINTYPE := staticlib
else #BINTYPE & suffix .so/a
$2_BINTYPE := executable
endif #BINTYPE & suffix .so/a
endif #target_BINTYPE undefined

# Ensure that target_LIBS has a value
ifeq "$$(origin $2_LIBS)" "undefined"
$2_LIBS := $$($1+LIBS)
endif #target_LIBS undefined

# Ensure that target_USE_LIBPWNABLEHARNESS has a value
ifeq "$$(origin $2_USE_LIBPWNABLEHARNESS)" "undefined"
$2_USE_LIBPWNABLEHARNESS := $$($1+USE_LIBPWNABLEHARNESS)
endif

# Ensure that target_NO_UNBUFFERED_STDIO has a value
ifeq "$$(origin $2_NO_UNBUFFERED_STDIO)" "undefined"
$2_NO_UNBUFFERED_STDIO := $$($1+NO_UNBUFFERED_STDIO)
endif

# Ensure that target_LDLIBS has a value
ifeq "$$(origin $2_LDLIBS)" "undefined"
$2_LDLIBS := $$($1+LDLIBS)
endif #target_LDLIBS undefined

# Add dependency on libpwnableharness[32|64] if requested
ifdef $2_USE_LIBPWNABLEHARNESS
$2_ALLLIBS := $$($2_LIBS) $(BUILD)/libpwnableharness$$($2_BITS).so
else
$2_ALLLIBS := $$($2_LIBS)
endif

# Build and link in the stdio_unbuffer.c source file unless opted out
ifndef $2_NO_UNBUFFERED_STDIO
$2_OBJS := $$($2_OBJS) $$($1+BUILD)/$2_objs/stdio_unbuffer.o

# Compiler rule for stdio_unbuffer.o
$$($1+BUILD)/$2_objs/stdio_unbuffer.o: stdio_unbuffer.c
	$$(_v)$$($2_CC) -m$$($2_BITS) $$($2_OFLAGS) $$($2_CFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

endif

# If additional shared libraries should be linked, allow loading them from the
# executable's directory and from /usr/local/lib
ifdef $2_ALLLIBS
ifdef IS_LINUX
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-rpath,/usr/local/lib,-rpath,`printf "\044"`ORIGIN
else ifdef IS_MAC
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-rpath,/usr/local/lib,-rpath,@executable_path
endif #IS_LINUX/IS_MAC
endif #target_ALLLIBS

# On macOS, dylibs need an "install name" to allow them to be loaded from the
# executable's directory
ifeq "$$($2_BINTYPE)" "dynamiclib"
ifdef IS_MAC
$2_LDFLAGS := $$($2_LDFLAGS) -install_name @rpath/$2
endif #IS_MAC
endif #dynamiclib

# Convert a list of dynamic library names into linker arguments
ifdef IS_LINUX
$2_LIBPATHS := $$(sort $$(patsubst %/,%,$$(dir $$($2_ALLLIBS))))
$2_LDFLAGS := $$($2_LDFLAGS) $$(addprefix -L,$$($2_LIBPATHS))
$2_LDLIBS := $$($2_LDLIBS) $$(addprefix -l:,$$(notdir $$($2_ALLLIBS)))
else ifdef IS_MAC
$2_LDLIBS := $$($2_LDLIBS) $$($2_ALLLIBS)
endif


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

# RELRO (Read-only relocations), only works on Linux
ifdef IS_LINUX
ifdef $2_RELRO
ifneq "$$($2_RELRO)" "partial"
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-z,relro,-z,now
endif #partial
else #RELRO
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-z,norelro
endif #RELRO
endif #IS_LINUX

# Stack canary
ifndef $2_CANARY
$2_CFLAGS := $$($2_CFLAGS) -fno-stack-protector
$2_CXXFLAGS := $$($2_CXXFLAGS) -fno-stack-protector
endif

# NX (No Execute) aka DEP (Data Execution Prevention) aka W^X (Write XOR eXecute)
ifndef $2_NX
ifdef IS_LINUX
$2_LDFLAGS := $$($2_LDFLAGS) -z execstack
else ifdef IS_MAC
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-allow_stack_execute
endif #OS
endif #target_NX

# ASLR (Address Space Layout Randomization)
ifdef $2_ASLR
$2_CFLAGS := $$($2_CFLAGS) -fPIC
$2_CXXFLAGS := $$($2_CXXFLAGS) -fPIC
ifeq "$$($2_BINTYPE)" "executable"
ifdef IS_LINUX
$2_LDFLAGS := $$($2_LDFLAGS) -pie
else ifdef IS_MAC
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-pie
endif #IS_LINUX/IS_MAC
endif #executable
else #ASLR
ifeq "$$($2_BINTYPE)" "executable"
ifdef IS_LINUX
$2_LDFLAGS := $$($2_LDFLAGS) -no-pie
else ifdef IS_MAC
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-no_pie
endif #IS_LINUX/IS_MAC
endif #executable
endif #ASLR

# Strip symbols
ifdef $2_STRIP
ifdef IS_LINUX
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-s
else ifdef IS_MAC
$2_LDFLAGS := $$($2_LDFLAGS) -Wl,-S,-x
endif #IS_LINUX/IS_MAC
endif #STRIP

# Debug symbols
ifdef $2_DEBUG
$2_CFLAGS := $$($2_CFLAGS) -ggdb -DDEBUG=1 -UNDEBUG
$2_CXXFLAGS := $$($2_CXXFLAGS) -ggdb -DDEBUG=1 -UNDEBUG
$2_LDFLAGS := $$($2_LDFLAGS) -ggdb
else #DEBUG
$2_CFLAGS := $$($2_CFLAGS) -DNDEBUG=1
$2_CXXFLAGS := $$($2_CXXFLAGS) -DNDEBUG=1
endif #DEBUG

# Ensure directories are created for all object files
$2_OBJ_DIR_RULES := $$(addsuffix /.dir,$$(sort $$(patsubst %/,%,$$(dir $$($2_OBJS)))))
$$($2_OBJS): $$($2_OBJ_DIR_RULES)

# Rebuild all build products when the Build.mk is modified
$$($2_OBJS): $$($1+BUILD_MK) Macros.mk
$$($2_PRODUCT): $$($1+BUILD_MK) Macros.mk

# Compiler rule for C sources
$$(filter %.c.o,$$($2_OBJS)): $$($1+BUILD)/$2_objs/%.c.o: $1/%.c
	$$(_V)echo "Compiling $$<"
	$$(_v)$$($2_CC) -m$$($2_BITS) $$(sort -I. -I$1) $$($2_OFLAGS) $$($2_CFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compiler rule for C++ sources
$$(filter %.cpp.o,$$($2_OBJS)): $$($1+BUILD)/$2_objs/%.cpp.o: $1/%.cpp
	$$(_V)echo "Compiling $$<"
	$$(_v)$$($2_CXX) -m$$($2_BITS) $$(sort -I. -I$1) $$($2_OFLAGS) $$($2_CXXFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compilation dependency rules
-include $$($2_DEPS)

$2_PRODUCT_DIR_RULE := $$(patsubst %/,%,$$(dir $$($2_PRODUCT)))/.dir

ifeq "$$($2_BINTYPE)" "dynamiclib"
# Linker rule to produce the final target (specialization for shared libraries)
$$($2_PRODUCT): $$($2_OBJS) $$($2_ALLLIBS) $$($2_PRODUCT_DIR_RULE)
	$$(_V)echo "Linking shared library $$@"
	$$(_v)$$($2_LD) -m$$($2_BITS) -shared $$($2_LDFLAGS) \
		-o $$@ $$($2_OBJS) $$($2_LDLIBS)

else ifeq "$$($2_BINTYPE)" "executable"
# Linker rule to produce the final target (specialization for executables)
$$($2_PRODUCT): $$($2_OBJS) $$($2_ALLLIBS) $$($2_PRODUCT_DIR_RULE)
	$$(_V)echo "Linking executable $$@"
	$$(_v)$$($2_LD) -m$$($2_BITS) $$($2_LDFLAGS) \
		-o $$@ $$($2_OBJS) $$($2_LDLIBS)

else ifeq "$$($2_BINTYPE)" "staticlib"
# Archive rule to produce the final target (specialication for static libraries)
$$($2_PRODUCT): $$($2_OBJS) $$($2_PRODUCT_DIR_RULE)
	$$(_V)echo "Archiving static library $$@"
	$$(_v)$$($2_AR) rcs $$@ $$^

else #dynamiclib & executable & staticlib

# Assume that the user will provide their own linker rule here
ifdef MKDEBUG
$$(info Not generating a linker rule for $1/$2 because its BINTYPE is "$$($2_BINTYPE)")
endif #MKDEBUG

endif #dynamiclib & executable & staticlib

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
# add_publish_rule($1: project directory, $2: path containing files to publish, $3: list of files under $2 to publish)
#
# Define a rule for copying a file to a project's publish directory
#####
define _add_publish_rule

ifdef MKDEBUG
$$(info add_publish_rule($1,$2,$3))
endif #MKDEBUG

$1+$2+DST := $$(addprefix $$(PUB_DIR)/$1/,$$(notdir $3))

publish[$1]: $$($1+$2+DST)

# Publishing rule
$$($1+$2+DST): $$(PUB_DIR)/$1/%: $2/%
	$$(_V)echo "Publishing $1/$$*"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

endef
add_publish_rule = $(eval $(call _add_publish_rule,$1,$2,$3))
#####




#####
# include_subdir($1: subdirectory)
#
# Check for a Build.mk file in the given directory. If one exists, include it and
# automatically generate all target dependencies and rules to build the products.
#####
define _include_subdir

# Allow overriding the Build.mk path for a directory
ifndef $1+BUILD_MK
$1+BUILD_MK := $$(wildcard $1/Build.mk)
endif

ifdef $1+BUILD_MK

# Append project directory to the list of discovered projects
PROJECT_LIST := $$(PROJECT_LIST) $1

# Exactly one of these must be defined by Build.mk
TARGET :=
TARGETS :=

# For advanced users that want to define custom build rules for a directory
PRODUCT :=
PRODUCTS :=

# Optional list of files to publish
PUBLISH :=
PUBLISH_BUILD :=
PUBLISH_TOP :=
PUBLISH_LIBC :=

# Deployment
DEPLOY_COMMAND :=
DEPLOY_DEPS :=

# Optional CTF flag management
FLAG_FILE := $(or $(wildcard $1/real_flag.txt),$(wildcard $1/flag.txt))
FLAG_DST := flag.txt
SET_FLAG_PERMISSIONS :=

# These can optionally be defined by Build.mk for Docker management
DOCKERFILE :=
DOCKER_IMAGE :=
DOCKER_IMAGE_TAG :=
DOCKER_IMAGE_CUSTOM :=
DOCKER_CONTAINER :=
DOCKER_CHALLENGE_NAME :=
DOCKER_CHALLENGE_PATH :=
DOCKER_BUILD_ARGS :=
DOCKER_BUILD_DEPS :=
DOCKER_PORTS :=
DOCKER_PORT_ARGS :=
DOCKER_RUN_ARGS :=
DOCKER_ENTRYPOINT_ARGS :=
DOCKER_RUNNABLE :=
DOCKER_BUILD_ONLY :=
DOCKER_TIMELIMIT :=
DOCKER_WRITEABLE :=

# These can optionally be defined to set directory-specific variables
BITS := $(DEFAULT_BITS)
OFLAGS := $(DEFAULT_OFLAGS)
CFLAGS := $(DEFAULT_CFLAGS)
CXXFLAGS := $(DEFAULT_CXXFLAGS)
LDFLAGS := $(DEFAULT_LDFLAGS)
SRCS := $$(patsubst $1/%,%,$$(foreach ext,c cpp,$$(wildcard $1/*.$$(ext))))
CC := $(DEFAULT_CC)
CXX := $(DEFAULT_CXX)
LD := $(DEFAULT_LD)
AR := $(DEFAULT_AR)
BINTYPE :=
LIBS :=
LDLIBS :=
USE_LIBPWNABLEHARNESS :=
NO_UNBUFFERED_STDIO :=

# Hardening flags
RELRO :=
CANARY :=
NX :=
ASLR :=
STRIP :=
DEBUG :=

# Set DIR+BUILD to the build directory for this project folder
ifeq "$1" "."
$1+BUILD := $$(BUILD)
else
$1+BUILD := $$(BUILD)/$1
endif

# Define DIR and BUILD_DIR for use by Build.mk files
DIR := $1
BUILD_DIR := $$($1+BUILD)

# First, include the subdirectory's makefile
ifdef MKDEBUG
$$(info Including $$($1+BUILD_MK))
endif
include $$($1+BUILD_MK)

# Look for new definition of TARGET/TARGETS
ifdef TARGET
# It's an error to define both TARGET and TARGETS
ifdef TARGETS
$$(error $$($1+BUILD_MK) defined both TARGET ($$(TARGET)) and TARGETS ($$(TARGETS))!)
endif
$1+TARGETS := $$(TARGET)
else ifdef TARGETS
$1+TARGETS := $$(TARGETS)
else
# Neither TARGET nor TARGETS are defined. This Build.mk file may still be useful for deployment
ifdef MKDEBUG
$$(warning $$($1+BUILD_MK) defines no targets.)
endif
$1+TARGETS :=
endif

# Path where the build target binary will be written
$1+PRODUCT := $$(PRODUCT)

# List of target files produced by Build.mk
$1+PRODUCTS := $$(PRODUCTS)
ifndef $1+PRODUCTS
ifdef $1+PRODUCT
ifneq "$$(words $$($1+TARGETS))" "1"
$$(error $$($1+BUILD_MK) defined multiple targets but also the PRODUCT variable)
endif #len(TARGETS) != 1
$1+PRODUCTS := $$($1+PRODUCT)
else #DIR+PRODUCT
$1+PRODUCTS := $$(addprefix $$($1+BUILD)/,$$($1+TARGETS))
endif #DIR+PRODUCT
endif #DIR+PRODUCTS

# Publishing
$1+PUBLISH := $$(PUBLISH)
$1+PUBLISH_BUILD := $$(PUBLISH_BUILD)
$1+PUBLISH_TOP := $$(PUBLISH_TOP)
$1+PUBLISH_LIBC := $$(PUBLISH_LIBC)
$1+PUBLISH_PROJ_FILES := $$(addprefix $1/,$$($1+PUBLISH))
$1+PUBLISH_BUILD_FILES := $$(addprefix $$($1+BUILD)/,$$($1+PUBLISH_BUILD))
$1+PUBLISH_ALL_FILES := $$(sort $$($1+PUBLISH_PROJ_FILES) $$($1+PUBLISH_BUILD_FILES) $$(PUBLISH_TOP))

# Deployment
$1+DEPLOY_COMMAND := $$(DEPLOY_COMMAND)
$1+DEPLOY_DEPS := $$(DEPLOY_DEPS)

# CTF flag management
$1+FLAG_FILE := $$(FLAG_FILE)
$1+FLAG_DST := $$(FLAG_DST)
$1+SET_FLAG_PERMISSIONS := $$(SET_FLAG_PERMISSIONS)

# Docker variables
$1+DOCKERFILE := $$(DOCKERFILE)
$1+DOCKER_IMAGE := $$(DOCKER_IMAGE)
$1+DOCKER_IMAGE_TAG := $$(DOCKER_IMAGE_TAG)
$1+DOCKER_IMAGE_CUSTOM := $$(DOCKER_IMAGE_CUSTOM)
$1+DOCKER_CONTAINER := $$(DOCKER_CONTAINER)
$1+DOCKER_CHALLENGE_NAME := $$(DOCKER_CHALLENGE_NAME)
$1+DOCKER_CHALLENGE_PATH := $$(DOCKER_CHALLENGE_PATH)
$1+DOCKER_BUILD_ARGS := $$(DOCKER_BUILD_ARGS)
$1+DOCKER_BUILD_DEPS := $$(DOCKER_BUILD_DEPS)
$1+DOCKER_PORTS := $$(DOCKER_PORTS)
$1+DOCKER_PORT_ARGS := $$(DOCKER_PORT_ARGS)
$1+DOCKER_RUN_ARGS := $$(DOCKER_RUN_ARGS)
$1+DOCKER_ENTRYPOINT_ARGS := $$(DOCKER_ENTRYPOINT_ARGS)
$1+DOCKER_RUNNABLE := $$(DOCKER_RUNNABLE)
$1+DOCKER_BUILD_ONLY := $$(DOCKER_BUILD_ONLY)
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
$1+AR := $$(AR)
$1+BINTYPE := $$(BINTYPE)
$1+LIBS := $$(LIBS)
$1+LDLIBS := $$(LDLIBS)
$1+USE_LIBPWNABLEHARNESS := $$(USE_LIBPWNABLEHARNESS)
$1+NO_UNBUFFERED_STDIO := $$(NO_UNBUFFERED_STDIO)

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
ifdef $1+PUBLISH_ALL_FILES

.PHONY: publish[$1]
publish: publish[$1]

# Generate all the real publish rules based on the source directory
$1+PUBLISH_DIRS := $$(sort $$(patsubst %/,%,$$(dir $$($1+PUBLISH_ALL_FILES))))
$$(foreach d,$$($1+PUBLISH_DIRS),$$(call add_publish_rule,$1,$$d,$$(filter $$d/%,$$($1+PUBLISH_ALL_FILES))))

endif #$1+PUBLISH_ALL_FILES

# Deploy rules
ifdef $1+DEPLOY_COMMAND

deploy: deploy[$1]

deploy[$1]: $$($1+DEPLOY_DEPS)
	$$(_V)echo "Deploying $1"
	$$(_v)cd $1 && $$($1+DEPLOY_COMMAND)

.PHONY: deploy[$1]

endif #$1+DEPLOY_COMMAND

# Clean rules
clean:: clean[$1]

clean[$1]:
	$$(_V)echo "Removing build directory and products for $1"
	$$(_v)rm -rf $$($1+BUILD) $$($1+PRODUCTS)

.PHONY: clean[$1]

## Docker variables

ifdef $1+DOCKER_COMPOSE
$$(call docker_compose,$1,$$(notdir $1))
endif #DOCKER_COMPOSE

# If DOCKER_IMAGE was defined by Build.mk, add docker rules.
ifdef $1+DOCKER_IMAGE

# Define variables for dependencies (like docker-build[var]) and the argument
ifdef $1+DOCKER_IMAGE_TAG
$1+DOCKER_IMAGE_DEP := $$($1+DOCKER_IMAGE).$$($1+DOCKER_IMAGE_TAG)
$1+DOCKER_TAG_ARG := $$($1+DOCKER_IMAGE):$$($1+DOCKER_IMAGE_TAG)
else #DIR+DOCKER_IMAGE_TAG
$1+DOCKER_IMAGE_DEP := $$($1+DOCKER_IMAGE)
$1+DOCKER_TAG_ARG := $$($1+DOCKER_IMAGE)
endif #DIR+DOCKER_IMAGE_TAG

# Check if there is a Dockerfile in this directory
ifndef $1+DOCKERFILE
$1+DOCKERFILE := $$(wildcard $1/Dockerfile)

# If $1+Dockerfile doesn't exist, we will use the default Dockerfile
ifndef $1+DOCKERFILE
$1+DOCKERFILE := $1/default.Dockerfile

# Add a rule to copy the default.Dockerfile to the project directory
$1/default.Dockerfile: default.Dockerfile
	$$(_V)echo 'Copying $$< to $$@'
	$$(_v)cp $$< $$@

endif #exists DIR+Dockerfile
endif #DOCKERFILE

# Docker images depend on the base PwnableHarness Docker image
ifneq "$$($1+DOCKER_IMAGE)" "c0deh4cker/pwnableharness"
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) docker-build[c0deh4cker/pwnableharness]
endif
endif

# Add the Dockerfile as a dependency for the docker-build target
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) $$($1+DOCKERFILE)

# The Build.mk file is a dependency for the docker-build target
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) $$($1+BUILD_MK) Macros.mk

# Ensure that DIR+DOCKER_CHALLENGE_NAME has a value. Default to the
# first target in DIR+TARGETS, or if that's not defined, the name of the image
ifdef $1+DOCKER_CHALLENGE_NAME
$1+DOCKER_RUNNABLE := true
else
ifneq "$1" "."
$1+DOCKER_CHALLENGE_NAME := $$(or $$(firstword $$($1+TARGETS)),$$($1+DOCKER_IMAGE))
endif
endif

# Ensure that DIR+DOCKER_CHALLENGE_PATH has a value. Default to the path to the
# built challenge binary
ifndef $1+DOCKER_CHALLENGE_PATH
ifneq "$1" "."
$1+DOCKER_CHALLENGE_PATH := $$(firstword $$($1+PRODUCTS))
endif
endif
ifdef $1+DOCKER_CHALLENGE_PATH
$1+DOCKER_BUILD_DEPS := $$($1+DOCKER_BUILD_DEPS) $$($1+DOCKER_CHALLENGE_PATH)
endif

# Ensure that DIR+DOCKER_CONTAINER has a value. Default to the Docker image name,
# or if that's not defined, the challenge name
ifdef $1+DOCKER_CONTAINER
$1+DOCKER_RUNNABLE := true
else
$1+DOCKER_CONTAINER := $$(or $$(notdir $$($1+DOCKER_IMAGE)),$$($1+DOCKER_CHALLENGE_NAME))
endif

# Use DOCKER_PORTS to produce arguments for binding host ports
ifdef $1+DOCKER_PORTS
$1+DOCKER_PORT_ARGS := $$(foreach port,$$($1+DOCKER_PORTS),-p $$(port):$$(port))
$1+DOCKER_RUNNABLE := true

ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "PORT=$$(firstword $$($1+DOCKER_PORTS))"
endif #DOCKER_IMAGE_CUSTOM
endif #DOCKER_PORTS

# Pass DOCKER_TIMELIMIT through as a build arg
ifdef $1+DOCKER_TIMELIMIT
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "TIMELIMIT=$$($1+DOCKER_TIMELIMIT)"
endif #DOCKER_IMAGE_CUSTOM
endif #DOCKER_TIMELIMIT

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

# Apply DOCKER_BUILD_ONLY to cancel out DOCKER_RUNNABLE
ifdef $1+DOCKER_BUILD_ONLY
$1+DOCKER_RUNNABLE :=
endif

# Append CHALLENGE_NAME, CHALLENGE_PATH, and DIR to the list of docker build arg
ifneq "$1" "."
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) \
	--build-arg "CHALLENGE_NAME=$$($1+DOCKER_CHALLENGE_NAME)" \
	--build-arg "CHALLENGE_PATH=$$($1+DOCKER_CHALLENGE_PATH)"

endif #DOCKER_IMAGE_CUSTOM
endif #Not top-level (building PwnableHarness itself)

# Automatic flag support is only provided for non-custom Docker images
ifndef $1+DOCKER_IMAGE_CUSTOM

# Adding the flag to the docker image
$1+HAS_FLAG :=
ifdef $1+FLAG_FILE
ifdef $1+FLAG_DST
ifdef MKDEBUG
$$(info Preparing flag for docker image $$($1+DOCKER_TAG_ARG) in $$($1+FLAG_DST))
endif #MKDEBUG

$1+HAS_FLAG := 1
$1+DOCKER_BUILD_ARGS := $$($1+DOCKER_BUILD_ARGS) --build-arg "FLAG_DST=$$($1+FLAG_DST)"
$1+DOCKER_RUN_ARGS := $$($1+DOCKER_RUN_ARGS) -v $$(abspath $$($1+FLAG_FILE)):/home/$$($1+DOCKER_CHALLENGE_NAME)/$$($1+FLAG_DST):ro
endif #FLAG_DST
endif #FLAG_FILE

endif #DOCKER_IMAGE_CUSTOM

# When setting the flag permissions, we need to tell Docker to ignore the flag
# during the docker build process, as the flag file will not be readable.
$1+DOCKER_START_DEPS :=
ifdef $1+SET_FLAG_PERMISSIONS
ifdef $1+HAS_FLAG
$1+DOCKER_START_DEPS := docker-flag[$$($1+DOCKER_CONTAINER)]
endif #HAS_FLAG
endif #SET_FLAG_PERMISSIONS

# Assume that DOCKER_BUILD_ARGS is already formatted as a list of "--build-arg name=value"
$1+DOCKER_BUILD_FLAGS := $$($1+DOCKER_BUILD_ARGS)


## Docker build rules

# Build a docker image
docker-build: docker-build[$$($1+DOCKER_IMAGE_DEP)]

# This only rebuilds the docker image if any of its prerequisites have
# been changed since the last docker build
docker-build[$$($1+DOCKER_IMAGE_DEP)]: $$($1+BUILD)/.docker_build_marker

# Create a marker file to track last docker build time
$$($1+BUILD)/.docker_build_marker: $$($1+PRODUCTS) $$($1+DOCKER_BUILD_DEPS) $$($1+BUILD)/.dir
	$$(_V)echo "Building docker image $$($1+DOCKER_TAG_ARG)"
	$$(_v)docker build -t $$($1+DOCKER_TAG_ARG) $$($1+DOCKER_BUILD_FLAGS) -f $$($1+DOCKERFILE) . \
		&& touch $$@

# Force build a docker image
docker-rebuild: docker-rebuild[$$($1+DOCKER_IMAGE_DEP)]

# This rebuilds the docker image no matter what
docker-rebuild[$$($1+DOCKER_IMAGE_DEP)]: | $$($1+PRODUCTS) $$($1+DOCKER_BUILD_DEPS) $$($1+BUILD)/.dir
	$$(_V)echo "Rebuilding docker image $$($1+DOCKER_TAG_ARG)"
	$$(_v)docker build -t $$($1+DOCKER_TAG_ARG) $$($1+DOCKER_BUILD_FLAGS) -f $$($1+DOCKERFILE) . \
		&& touch $$($1+BUILD)/.docker_build_marker

# Rule for removing a docker image and any containers based on it
docker-clean: docker-clean[$$($1+DOCKER_IMAGE_DEP)]

# Force remove the container and image
docker-clean[$$($1+DOCKER_IMAGE_DEP)]:
	$$(_V)echo "Cleaning docker image $$($1+DOCKER_TAG_ARG)"
ifdef $1+DOCKER_RUNNABLE
	$$(_v)docker rm -f $$($1+DOCKER_CONTAINER) >/dev/null 2>&1 || true
endif
	$$(_v)docker rmi -f $$($1+DOCKER_TAG_ARG) >/dev/null 2>&1 || true
	$$(_v)rm -f $$($1+BUILD)/.docker_build_marker

## Docker run rules

ifdef $1+DOCKER_RUNNABLE

# Rule for starting a docker container
docker-start: docker-start[$$($1+DOCKER_CONTAINER)]

# When starting a container, make sure the docker image is built
# and up to date
docker-start[$$($1+DOCKER_CONTAINER)]: docker-build[$$($1+DOCKER_IMAGE_DEP)] $$($1+DOCKER_START_DEPS)
	$$(_V)echo "Starting docker container $$($1+DOCKER_CONTAINER) from image $$($1+DOCKER_TAG_ARG)"
	$$(_v)docker rm -f $$($1+DOCKER_CONTAINER) >/dev/null 2>&1 || true
	$$(_v)docker run -itd --restart=unless-stopped --name $$($1+DOCKER_CONTAINER) \
		-v /etc/localtime:/etc/localtime:ro $$($1+DOCKER_PORT_ARGS) \
		$$($1+DOCKER_RUN_ARGS) $$($1+DOCKER_TAG_ARG) $$($1+DOCKER_ENTRYPOINT_ARGS)

.PHONY: docker-start[$$($1+DOCKER_CONTAINER)]

# Rule for setting flag permissions
ifdef $1+SET_FLAG_PERMISSIONS

docker-flag[$$($1+DOCKER_CONTAINER)]: $1/.dockerignore

# Need to tell docker to ignore this file, otherwise it'll fail as it
# doesn't have read access to it.
$1/.dockerignore: $$($1+FLAG_FILE)
	$$(_v)sudo chown root:1337 $$($1+FLAG_FILE) \
		&& sudo chmod 0640 $$($1+FLAG_FILE) \
		&& echo $$(patsubst $1/%,%,$$($1+FLAG_FILE)) > $$@

.PHONY: docker-flag[$$($1+DOCKER_CONTAINER)]

endif #SET_FLAG_PERMISSIONS


# Rule for restarting a docker container
docker-restart: docker-restart[$$($1+DOCKER_CONTAINER)]

# Restart a docker container
docker-restart[$$($1+DOCKER_CONTAINER)]:
	$$(_V)echo "Restarting docker container $$($1+DOCKER_CONTAINER)"
	$$(_v)docker restart $$($1+DOCKER_CONTAINER)

.PHONY: docker-restart[$$($1+DOCKER_CONTAINER)]

# Rule for stopping a docker container
docker-stop: docker-stop[$$($1+DOCKER_CONTAINER)]

# Stop the docker container
docker-stop[$$($1+DOCKER_CONTAINER)]:
	$$(_V)echo "Stopping docker container $$($1+DOCKER_CONTAINER)"
	$$(_v)docker stop $$($1+DOCKER_CONTAINER)

.PHONY: docker-stop[$$($1+DOCKER_CONTAINER)]

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

# Copy the libc from Docker only if the challenge builds a Docker image
ifdef $1+DOCKER_IMAGE
# If the challenge has a Docker image, copy the libc from there
$$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC): docker-build[$$($1+DOCKER_IMAGE_DEP)] | $$(PUB_DIR)/$1/.dir
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LIBC) from docker image $$($1+DOCKER_TAG_ARG):$$($1+LIBC_PATH)"
	$$(_v)mkdir -p $$(@D) && docker run --rm --entrypoint /bin/cat $$($1+DOCKER_TAG_ARG) $$($1+LIBC_PATH) > $$@

else #DOCKER_IMAGE
# If the challenge doesn't run in Docker, copy the system's libc
$$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC): $$($1+LIBC_PATH)
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LIBC) from $$<"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

endif #DOCKER_IMAGE
endif #PUBLISH_LIBC
endif #DIR+BUILD_MK

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

# Ensure DIR+SUBDIRS has a value
ifndef $1+SUBDIRS
$1+SUBDIRS :=
endif

# Make a list of all items in this directory that are directories and strip the trailing "/"
$1+SUBDIRS := $$($1+SUBDIRS) $$(patsubst %/,%,$$(dir $$(wildcard $1/*/)))

# Remove current directory and blacklisted items from the list of subdirectories
$1+SUBDIRS := $$(filter-out $1 %.disabled $$(addprefix %/,$$(RECURSION_BLACKLIST)),$$($1+SUBDIRS))

# Strip off the leading "./" in the subdirectory names
$1+SUBDIRS := $$(sort $$(patsubst ./%,%,$$($1+SUBDIRS)))

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
