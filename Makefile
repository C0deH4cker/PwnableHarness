# By default, build the current project tree (which might be a subset of the
# workspace, if `pwnmake` was invoked below the workspace root).
build:
MAKECMDGOALS ?=

# For now, always use "linux/amd64" as the Docker platform
export DOCKER_DEFAULT_PLATFORM := linux/amd64

# Environment variables that may be defined by pwnmake
CONTAINER_BUILD ?=
PWNMAKE_VERSION ?=

# Which project tree in the workspace should be built?
PROJECT ?= .

# Container builds run from /PwnableHarness/workspace as their CWD
ifdef CONTAINER_BUILD
ROOT_DIR := /PwnableHarness
GIT_HASH := $(shell cat '$(ROOT_DIR)/.githash')
CONFIG_USE_PWNCC ?= 1
PWNCC_DIR := $(ROOT_DIR)
else #CONTAINER_BUILD
ROOT_DIR := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))
GIT_HASH := $(shell git -C '$(ROOT_DIR)' rev-parse HEAD)
PWNCC_DIR := $(patsubst ./%,%,$(ROOT_DIR)/pwncc)
PWNMAKE_DIR := pwnmake
endif #CONTAINER_BUILD

PWNABLEHARNESS_REPO := c0deh4cker/pwnableharness

# Define useful variables for special Makefile characters
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COLON := :
COMMA := ,
DOLLAR := $$
define HASH
#
endef
define NEWLINE


endef

# For debugging purposes
MKDEBUG ?=
MKTRACE ?=
DOCKER_DEBUG ?=

# Print all commands executed when VERBOSE is defined, but don't echo explanations
VERBOSE ?=
ifdef VERBOSE
_v :=
_V := @$(HASH)
else
_v := @
_V := @
endif


ifdef MKDEBUG
$(info Including $(ROOT_DIR)/Versions.mk)
endif #MKDEBUG
include $(ROOT_DIR)/Versions.mk

# Path to the root build directory
ifndef BUILD
BUILD := .build
endif

# Path to the publish directory
PUB_DIR := publish

# List of PwnableHarness projects discovered
PROJECT_LIST :=

# List of PwnableHarness target rules available
TARGET_LIST :=

add_targets = $(eval TARGET_LIST += $1)
add_target = $(add_targets)
define _add_phony_target
.PHONY: $1

TARGET_LIST += $1
endef
add_phony_targets = $(eval $(call _add_phony_target,$1))
add_phony_target = $(add_phony_targets)

# Top-level (non-project) targets
$(call add_phony_targets,all env help list list-targets version)

# Define each of these general targets as aliases of that target for the selected project
PROJECT_TARGETS := build clean publish deploy docker-build docker-rebuild docker-start docker-restart docker-stop docker-clean
define _def_proj_targ
$$(call add_phony_targets,$1 $1-all)
$1: $1[$$(PROJECT)]
$1-all: $1[.]

endef #_def_proj_targ
def_proj_targ = $(eval $(call _def_proj_targ,$1))
$(foreach t,$(PROJECT_TARGETS),$(call def_proj_targ,$t))

# If there is a Config.mk present in the root of this workspace or a subdirectory, include it
ifdef MKDEBUG
$(info Including Config.mk $(wildcard */Config.mk) (if present))
endif #MKDEBUG
-include Config.mk $(wildcard */Config.mk)

# Provides information about currently supported Ubuntu versions:
# UBUNTU_VERSIONS: list[string version number]
# UBUNTU_ALIASES: list[string alias name]
# UBUNTU_VERSION_TO_ALIAS: map[string version number] -> string alias name
# UBUNTU_ALIAS_TO_VERSION: map[string alias name] -> string version number
# GLIBC_VERSIONS: list[string glibc version number]
# UBUNTU_TO_GLIBC: map[string version/alias] -> string glibc version number
# GLIBC_TO_UBUNTU: map[string glibc version number] -> string version number
ifdef MKDEBUG
$(info Including $(ROOT_DIR)/UbuntuVersions.mk)
endif #MKDEBUG
include $(ROOT_DIR)/UbuntuVersions.mk

# Basic OS detection (Windows is detected but not supported)
ifndef OS
OS := $(shell uname -s)
endif
IS_WIN :=
IS_LINUX :=
IS_MAC :=
ifeq "$(OS)" "Windows_NT"
IS_WIN := 1
else ifeq "$(OS)" "Linux"
IS_LINUX := 1
else ifeq "$(OS)" "Darwin"
IS_MAC := 1
endif

# Unless overridden in a Config.mk file, don't build 32-bit binaries on macOS.
ifdef IS_MAC
CONFIG_IGNORE_32BIT := true
endif #IS_MAC

DOCKER := docker$(if $(DOCKER_DEBUG), --debug)

# Define useful build macros
ifdef MKDEBUG
$(info Including $(ROOT_DIR)/Macros.mk)
endif #MKDEBUG
include $(ROOT_DIR)/Macros.mk

# The pwncc.mk file will use config options to decide what to define
ifdef MKDEBUG
$(info Including $(PWNCC_DIR)/pwncc.mk)
endif #MKDEBUG
include $(PWNCC_DIR)/pwncc.mk

# Directories to avoid recursing into
RECURSION_BLACKLIST ?=
RECURSION_BLACKLIST := \
	%/.build \
	%/$(BUILD) \
	./$(PUB_DIR) \
	%.disabled \
	%/workdir \
	%/.git \
	%/.cache \
	%/.docker \
	$(RECURSION_BLACKLIST)

ifndef CONTAINER_BUILD
RECURSION_BLACKLIST += ./$(PWNCC_DIR) ./$(PWNMAKE_DIR) ./bin ./core
ifndef WITH_EXAMPLES
# Only include examples when invoked like `make WITH_EXAMPLES=1`
RECURSION_BLACKLIST += ./examples
endif #WITH_EXAMPLES
endif #CONTAINER_BUILD

# Users of PwnableHarness aren't expected to build the core project and image
# themselves, but rather pull the pre-built images from Docker Hub.
ifdef CONFIG_I_AM_C0DEH4CKER_HEAR_ME_ROAR
$(call include_subdir,core)
ifndef CONTAINER_BUILD
# Responsible for building, tagging, and pushing the pwnmake builder images
ifdef MKDEBUG
$(info Including $(PWNMAKE_DIR)/pwnmake.mk)
endif #MKDEBUG
include $(PWNMAKE_DIR)/pwnmake.mk
endif #CONTAINER_BUILD
endif #C0deH4cker

# Recursively grab each subdirectory's Build.mk file and generate rules for its targets
$(call recurse_subdir,.)

# "make all" is an alias for "make build-all", which explicitly builds the
# whole workspace tree.
all: build-all

# Used by pwnmake.Dockerfile to create the /PwnableHarness/VERSION file
version:
	@echo '$(patsubst v%,%,$(PHMAKE_VERSION))'

# Used for debugging this Makefile
# `make PWNABLEHARNESS_VERSION?` will print the version of PwnableHarness being used
%?:
	$(info $* := $(value $*))
	@true

# Print environment
env:
	@export

# List discovered project directories that contain Build.mk files
list:
	@$(foreach x,$(sort $(PROJECT_LIST)),echo '$x';)

# List generated targets
list-targets:
	@$(foreach x,$(sort $(TARGET_LIST)),echo '$x';)

# Display a useful help message
help:
	@echo \
		  '# PwnableHarness: C/C++ build and Docker management system for CTF challenges' \
		'\n' \
		$(if $(CONTAINER_BUILD),, \
		'\n  The new, preferred way to run PwnableHarness targets is with `pwnmake`. This' \
		'\n  invocation runs all build and Docker management commands in a Docker container' \
		'\n  for increased portability and easier workspace configuration. You can also' \
		'\n  still use `make` from the PwnableHarness directory if you prefer.' \
		'\n' \
		) \
		'\n## Command line reference' \
		'\n' \
		'\n  Project-specific targets like `docker-build[project]` can also be used without' \
		'\n  an argument. When no argument is provided, it will run that target for all' \
		'\n  projects. So `docker-build` will build the Docker images for ALL projects.' \
		'\n  Note that descendent projects are included automatically. If you only want' \
		'\n  to run the target in the project but not its descendents, append "-one" to' \
		'\n  the target name (`docker-build[project]` becomes `docker-build-one[project]`).' \
		'\n' \
		'\n### Target descriptions:' \
		'\n' \
		'\n* `build[project]`:' \
		'\n         Compile and link all defined TARGETS for the given project.' \
		'\n         This is the default target, so running `pwnmake` without any provided' \
		'\n         target is the same as running `pwnmake build`.' \
		'\n* `clean[project]`:' \
		'\n         Deletes all build products for the given project. Running this target' \
		'\n         without an argument is effectively the same as `rm -rf .build`. Note' \
		'\n         that individual projects can provide custom `clean` actions by using' \
		'\n         the `clean::` multi-recipe target.' \
		'\n* `publish[project]`:' \
		'\n         Copy all files that a project requests to be published to the `publish`' \
		'\n         directory at the top level of the workspace. Projects can define the' \
		'\n         `PUBLISH`, `PUBLISH_BUILD`, and `PUBLISH_TOP` variables in their' \
		'\n         `Build.mk` file to specify which files should be published. All files' \
		'\n         to be published are ensured to be up to date. So, if a project defines' \
		'\n         `PUBLISH_BUILD := $$(TARGET)` and you run `publish` before building' \
		'\n         the executable, it will build that target and then copy it to the' \
		'\n         `publish` directory. Note that the `publish` directory mirrors your' \
		'\n         workspace'"'"'s directory structure. So if you have `foo/bar/Build.mk`' \
		'\n         which publishes its target (named `baz`), that will be copied to' \
		'\n         `publish/foo/bar/baz`. For serving published files over HTTP(S), it is' \
		'\n         useful to create symlinks from `/var/www/<path>` into the `publish`' \
		'\n         directory in your workspace. Just ensure that the http server has read' \
		'\n         access to the contents.' \
		'\n* `deploy[project]`:' \
		'\n         Without an argument, this is shorthand for `docker-start publish`.' \
		'\n         Projects can optionally define the `DEPLOY_COMMAND` variable in their' \
		'\n         `Build.mk` file, which is a command to be run from the project'"'"'s' \
		'\n         directory when running `deploy` or `deploy[project]`.' \
		'\n* `docker-build[project]`:' \
		'\n         Build the project'"'"'s Docker image, ensuring all dependencies are up to' \
		'\n         date. For example, editing a C file and then running the `docker-build`' \
		'\n         target will recompile the binary and rebuild the Docker image.' \
		'\n* `docker-rebuild[project]`:' \
		'\n         Force rebuild the project'"'"'s Docker image, even if all of its' \
		'\n         dependencies are up to date.' \
		'\n* `docker-start[project]`:' \
		'\n         Create and start the project'"'"'s Docker container, ensuring the Docker' \
		'\n         image it is based on is up to date.' \
		'\n* `docker-restart[project]`:' \
		'\n         Restart the project'"'"'s Docker container.' \
		'\n* `docker-stop[project]`:' \
		'\n         Stop the project'"'"'s Docker container.' \
		'\n* `docker-clean[project]`:' \
		'\n         Stop the project'"'"'s Docker container, and delete its image and any' \
		'\n         workdir volumes.' \
		'\n* `list`:' \
		'\n         Display a list of all discovered project directories.' \
		'\n* `list-targets`:' \
		'\n         Display a list of all provided targets.' \
		'\n' \
		'\n### Command-line variables:' \
		'\n' \
		'\n* `VERBOSE=1`:' \
		'\n         Echo each command as it executes instead of a concise description.' \
		$(if $(CONTAINER_BUILD),, \
		'\n* `WITH_EXAMPLES=1`:' \
		'\n         Include the example projects in the workspace.' \
		) \
		'\n* `MKDEBUG=1`:' \
		'\n         Output additional debug information about the PwnableHarness project' \
		'\n         discovery logic in its Makefiles.' \
		'\n' \
		'\n### Additional information:' \
		'\n' \
		'\n * To prevent a directory from being searched for `Build.mk` project files, you' \
		'\n   can rename it so it ends in `.disabled`. For example:' \
		'\n' \
		'\n```sh' \
		'\n# Don'"'"'t use Build.mk files under OldRepo' \
		'\nmv OldRepo OldRepo.disabled' \
		'\n# More concisely:' \
		'\nmv OldRepo{,.disabled}' \
		'\n```' \
		'\n' \
		'\n * You can create a `Config.mk` file in the top-level of your workspace (or any' \
		'\n   direct subdirectory) that will be included before all of the PwnableHarness' \
		'\n   Makefile code. This is mainly intended for defining variables prefixed with' \
		'\n   `CONFIG_*` or `DEFAULT_*`. Examples:' \
		'\n' \
		'\n   - `CONFIG_IGNORE_32BIT`: Don'"'"'t build 32-bit versions of PwnableHarness' \
		'\n   - `CONFIG_PUBLISH_LIBPWNABLEHARNESS`: Publish `libpwnableharness(32|64).so`' \
		'\n   - `DEFAULT_(BITS|OFLAGS|CFLAGS|CXXFLAGS|LDFLAGS|CC|CXX|LD|AR)`: Override the' \
		'\n     default value of each of these build variables for your workspace.' \
		'\n' \
		'\n * Any directory can contain an `After.mk` file, which is included during the' \
		'\n   project discovery phase after all subdirectories have been included. Project' \
		'\n   discovery is performed as a depth-first traversal. When visiting a directory,' \
		'\n   its `Build.mk` file will be included, then all of its subdirectories will be' \
		'\n   visited, and then its `After.mk` file will be included. Both `Build.mk` and' \
		'\n   `After.mk` are optional in each directory. `After.mk` is a good place for a' \
		'\n   parent/ancestor project to collect settings defined by its descendants.' \
	| sed 's/ $$//'

# Automatic creation of build directories
%/.dir:
	$(_v)mkdir -p $(@D) && touch $@

# Make sure that the .dir files aren't automatically deleted after building
.SECONDARY:

# Disable magic when a dependency looks like "-l<whatever>"
.LIBPATTERNS :=

# Whenever a recipe returns an error while building a file, make will delete that file (if it changes).
# This is useful to avoid corrupt build states where a file is considered up to date by its modification
# time, even though it holds incomplete/incorrect contents due to the error.
.DELETE_ON_ERROR:

# Disable old style suffix rules (the `-r` flag for make also disables these)
.SUFFIXES:
