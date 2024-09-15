# Make sure the default target is to "make all"
all:

# For now, always use "linux/amd64" as the Docker platform
export DOCKER_DEFAULT_PLATFORM ?= linux/amd64

# Environment variables that may be defined by pwnmake
CONTAINER_BUILD ?=
PWNMAKE_VERSION ?=

# Keep aligned with version in bin/pwnmake script
ifdef PWNABLEHARNESS_WIP
PWNABLEHARNESS_VERSION := wip
PWNABLEHARNESS_REPO := c0deh4cker/pwnableharness-wip
else #PWNABLEHARNESS_WIP
PWNABLEHARNESS_VERSION := v2.1
PWNABLEHARNESS_REPO := c0deh4cker/pwnableharness
endif #PWNABLEHARNESS_WIP

# Container builds run from /PwnableHarness/workspace as their CWD
ifdef CONTAINER_BUILD
ROOT_DIR := /PwnableHarness
PWNABLEHARNESS_CORE_PROJECT := $(ROOT_DIR)/core
else
ROOT_DIR := .
PWNABLEHARNESS_CORE_PROJECT := core
PWNABLE_BUILDER_DIR := builder
endif

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

# If there is a Config.mk present in the root of this workspace or a subdirectory, include it
-include Config.mk $(wildcard */Config.mk)

# Path to the root build directory
BUILD := .build
PWNABLEHARNESS_CORE_PROJECT_BUILD := $(BUILD)/PwnableHarness

# Path to the publish directory
PUB_DIR := publish

# For debugging development of this Makefile
MKDEBUG ?=
MKTRACE ?=

# Print all commands executed when VERBOSE is defined, but don't echo explanations
VERBOSE ?=
ifdef VERBOSE
_v :=
_V := @$(HASH)
else
_v := @
_V := @
endif

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

# Define useful build macros
include $(ROOT_DIR)/Macros.mk

# Directories to avoid recursing into
RECURSION_BLACKLIST ?=
RECURSION_BLACKLIST := $(BUILD) $(PUB_DIR) bin .git .docker $(RECURSION_BLACKLIST)

# Only include examples when invoked like `make WITH_EXAMPLES=1`
ifndef CONTAINER_BUILD
ifndef WITH_EXAMPLES
RECURSION_BLACKLIST := examples $(RECURSION_BLACKLIST)
endif #WITH_EXAMPLES
endif #CONTAINER_BUILD

# List of PwnableHarness projects discovered
PROJECT_LIST :=

# List of PwnableHarness target rules available
TARGET_LIST := all help list list-targets core clean publish deploy \
	docker-build docker-rebuild docker-start docker-restart docker-stop docker-clean

add_targets = $(eval TARGET_LIST := $$(TARGET_LIST) $1)
add_target = $(add_targets)
define _add_phony_target

.PHONY: $1

TARGET_LIST := $$(TARGET_LIST) $1

endef
add_phony_targets = $(eval $(call _add_phony_target,$1))
add_phony_target = $(add_phony_targets)

# Make sure to include the core project before user projects
$(call include_subdir,$(PWNABLEHARNESS_CORE_PROJECT))

# Responsible for building, tagging, and pushing the pwnmake builder images
ifndef CONTAINER_BUILD
include $(PWNABLE_BUILDER_DIR)/BuilderImage.mk
endif #CONTAINER_BUILD

# Recursively grab each subdirectory's Build.mk file and generate rules for its targets
$(call recurse_subdir,.)

# Used for debugging this Makefile
# `make PWNABLEHARNESS_VERSION?` will print the version of PwnableHarness being used
%?:
	@echo '$* := $($*)'

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
		'\n  Targets with arguments like `docker-build[image]` can also be used without an' \
		'\n  argument. When no argument is provided, it will run that target for all' \
		'\n  possible values of that parameter. So `docker-build` will build ALL Docker' \
		'\n  images in the workspace.' \
		'\n' \
		'\n### Target descriptions:' \
		'\n' \
		'\n* `all[project]`:' \
		'\n         Compile and link all defined TARGETS for the given project.' \
		'\n         This is the default target, so running `pwnmake` without any provided' \
		'\n         target is the same as running `pwnmake all`.' \
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
		'\n         directory in your workspace. Just ensure that the http server user has' \
		'\n         read access to the contents.' \
		'\n* `deploy[project]`:' \
		'\n         Without an argument, this is shorthand for `docker-start publish`.' \
		'\n         Projects can optionally define the `DEPLOY_COMMAND` variable in their' \
		'\n         `Build.mk` file, which is a command to be run from the project'"'"'s' \
		'\n         directory when running `deploy` or `deploy[project]`.' \
		'\n* `docker-build[image]`:' \
		'\n         Build the named Docker image, ensuring all dependencies are up to date.' \
		'\n         For example, editing a C file and then running the `docker-build`' \
		'\n         target will recompile the binary and rebuild the Docker image.' \
		'\n* `docker-rebuild[image]`:' \
		'\n         Force rebuild a named Docker image, even if all of its dependencies are' \
		'\n         up to date.' \
		'\n* `docker-start[container]`:' \
		'\n         Create and start the named Docker container, ensuring the Docker image' \
		'\n         it is based on is up to date.' \
		'\n* `docker-restart[container]`:' \
		'\n         Restart the named Docker container.' \
		'\n* `docker-stop[container]`:' \
		'\n         Stop the named Docker container.' \
		'\n* `docker-clean[image]`:' \
		'\n         Stop any container running from this Docker image and delete it, then' \
		'\n         delete the Docker image. Also will delete the associated Docker volume' \
		'\n         for the workdir, if one exists. Running this without an argument will' \
		'\n         stop all containers and delete all images that are defined by any' \
		'\n         project in the workspace.' \
		'\n* `list`:' \
		'\n         Display a list of all discovered project directories.' \
		'\n* `list-targets`:' \
		'\n         Display a list of all provided targets.' \
		'\n* `core`:' \
		'\n         Build only the core PwnableHarness binaries.' \
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

# Running "make core" builds only PwnableHarness binaries
core: all[$(ROOT_DIR)]

# Define "make clean" as a multi-recipe target so that Build.mk files may add their own clean actions
clean::

# Running "make deploy" will build and start Docker containers and publish challenge artifacts
deploy: docker-start publish

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

# Global targets that are "phony", aka don't name a file to be created
.PHONY: all core clean publish deploy env list list-targets help

# Phony Docker targets
.PHONY: docker-build docker-rebuild docker-start docker-restart docker-stop docker-clean
