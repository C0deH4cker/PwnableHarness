# Make sure the default target is to "make all"
all:

# Path to the root build directory
BUILD := build

# Path to the publish directory (this could be a symlink to /var/www/html)
PUB_DIR := publish

# For debugging development of this Makefile
MKDEBUG ?=

# Print all commands executed when VERBOSE is defined
VERBOSE ?=
_v = $(if $(VERBOSE),,@)
_V = $(if $(VERBOSE),@\#,@)

# Define useful build macros
include Macros.mk

# Directories to avoid recursing into
RECURSION_BLACKLIST ?=
RECURSION_BLACKLIST := $(BUILD) $(PUB_DIR) .git $(RECURSION_BLACKLIST)

# Only include examples when invoked like `make WITH_EXAMPLES=1`
ifndef WITH_EXAMPLES
RECURSION_BLACKLIST := stack0 $(RECURSION_BLACKLIST)
endif

# Recursively grab each subdirectory's Build.mk file and generate rules for its targets
$(call recurse_subdir,.)

# Used for debugging this Makefile
# `make stack0/DOCKER_PORTS?` will print the ports exposed by stack0's Docker container
%?:
	@echo '$* := $($*)'

# Running "make base" builds only libpwnableharness*.so
base: all[.]

# Make sure that the .dir files aren't automatically deleted after building
.SECONDARY:

# Global targets that are "phony", aka don't name a file to be created
.PHONY: all base clean publish

# Phony Docker targets
.PHONY: docker-build docker-rebuild docker-start docker-restart docker-stop docker-clean
