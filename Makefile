# Make sure the default target is to "make all"
all:

# Path to the root build directory
BUILD := build

# Path to the publish directory (this is generally a symlink to /var/www/html)
PUB_DIR := publish

# Print all commands executed when VERBOSE is defined
VERBOSE ?=
_v = $(if $(VERBOSE),,@)

# Define useful build macros
include Macros.mk

# Include each subdirectory's Build.mk (including this directory)
$(call include_subdir,.)

# Running "make base" builds only libpwnableharness*.so
base: all[.]

# Make sure that the .dir files aren't automatically deleted after building
.SECONDARY:

# Global targets that are "phony", aka don't name a file to be created
.PHONY: all base clean publish

# Phony Docker targets
.PHONY: docker-build docker-rebuild docker-start docker-restart docker-stop docker-clean
