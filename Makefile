# Make sure the default target is to "make all"
all:

# Current Docker image name and tag
PWNABLEHARNESS_REPO := c0deh4cker/pwnableharness
PWNABLEHARNESS_VERSION := 2.0b1

# Directory in the build container where the workspace is bind-mounted
ifdef CONTAINER_BUILD
WORKSPACE := workspace
else #CONTAINER_BUILD
WORKSPACE := .
endif #CONTAINER_BUILD

# If there is a Config.mk present in the root of this repo or a subdirectory, include it
-include $(WORKSPACE)/Config.mk $(wildcard $(WORKSPACE)/*/Config.mk)

# Path to the root build directory
BUILD := $(WORKSPACE)/.build

# Path to the publish directory (this could be a symlink to /var/www/html)
PUB_DIR := $(WORKSPACE)/publish

# For debugging development of this Makefile
MKDEBUG ?=

# Print all commands executed when VERBOSE is defined, but don't echo explanations
define HASH
#
endef
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

# Define useful build macros
include Macros.mk

# Directories to avoid recursing into
RECURSION_BLACKLIST ?=
RECURSION_BLACKLIST := $(BUILD) $(PUB_DIR) bin .git $(RECURSION_BLACKLIST)

# Only include examples when invoked like `make WITH_EXAMPLES=1`
ifndef WITH_EXAMPLES
RECURSION_BLACKLIST := examples $(RECURSION_BLACKLIST)
endif

# List of PwnableHarness projects discovered
PROJECT_LIST :=

# Recursively grab each subdirectory's Build.mk file and generate rules for its targets
$(call recurse_subdir,.)

# Used for debugging this Makefile
# `make stack0:DOCKER_PORTS?` will print the ports exposed by stack0's Docker container
%?:
	@echo '$* := $($*)'

list:
	@$(foreach x,$(sort $(PROJECT_LIST)),echo '$x';)

# Running "make base" builds only PwnableHarness binaries
base: all[.]

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

# Global targets that are "phony", aka don't name a file to be created
.PHONY: all base clean publish deploy

# Phony Docker targets
.PHONY: docker-build docker-rebuild docker-start docker-restart docker-stop docker-clean
