# This is not intended to be an example Build.mk file to reference.
# Please instead look at examples/stack0/Build.mk for reference.

PWNABLE_DIR := $(DIR)
PWNABLE_BUILD := $(BUILD_DIR)

# Provides information about currently supported Ubuntu versions:
# UBUNTU_VERSIONS: list[string version number]
# UBUNTU_ALIASES: list[string alias name]
# UBUNTU_VERSION_TO_ALIAS: map[string version number] -> string alias name
# UBUNTU_ALIAS_TO_VERSION: map[string alias name] -> string version number
include $(PWNABLE_DIR)/UbuntuVersions.mk

PWNABLE_LIB32 := libpwnableharness32.so
PWNABLE_LIB64 := libpwnableharness64.so
PWNABLE_SERVER := pwnableserver
TARGETS := $(PWNABLE_LIB64) $(PWNABLE_SERVER)

ifndef CONFIG_IGNORE_32BIT
TARGETS := $(TARGETS) $(PWNABLE_LIB32)
endif #CONFIG_IGNORE_32BIT

CFLAGS := -Wall -Wextra -Wno-unused-parameter -Werror

ASLR := 1
RELRO := 1
CANARY := 1
NX := 1

$(PWNABLE_LIB32)_BITS := 32
$(PWNABLE_LIB32)_SRCS := pwnable_harness.c
$(PWNABLE_LIB32)_DEBUG := true

$(PWNABLE_LIB64)_BITS := 64
$(PWNABLE_LIB64)_SRCS := pwnable_harness.c
$(PWNABLE_LIB64)_DEBUG := true

$(PWNABLE_SERVER)_BITS := 64
$(PWNABLE_SERVER)_SRCS := pwnable_server.c
$(PWNABLE_SERVER)_DEBUG := true
$(PWNABLE_SERVER)_USE_LIBPWNABLEHARNESS := true

ifdef CONFIG_PUBLISH_LIBPWNABLEHARNESS
PUBLISH := $(PWNABLE_LIB64)

ifndef CONFIG_IGNORE_32BIT
PUBLISH := $(PUBLISH) $(PWNABLE_LIB32)
endif #CONFIG_IGNORE_32BIT
endif #CONFIG_PUBLISH_LIBPWNABLEHARNESS


# For use by BaseImage.mk
PWNABLE_TARGETS := $(TARGETS)

# Responsible for building, tagging, and pushing the base PwnableHarness images
include $(PWNABLE_DIR)/BaseImage.mk
