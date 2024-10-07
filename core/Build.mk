# This is not intended to be an example Build.mk file to reference.
# Please instead look at examples/stack0/Build.mk for reference.

CORE_DIR := $(DIR)
CORE_BUILD := $(BUILD_DIR)

CORE_LIB32 := libpwnableharness32.so
CORE_LIB64 := libpwnableharness64.so
CORE_SERVER := pwnableserver
TARGETS := $(CORE_LIB64) $(CORE_SERVER)

ifndef CONFIG_IGNORE_32BIT
TARGETS := $(TARGETS) $(CORE_LIB32)
endif #CONFIG_IGNORE_32BIT

CFLAGS := -Wall -Wextra -Werror

ASLR := 1
RELRO := 1
CANARY := 1
NX := 1

$(CORE_LIB32)_BITS := 32
$(CORE_LIB32)_SRCS := pwnable_harness.c
$(CORE_LIB32)_DEBUG := true

$(CORE_LIB64)_BITS := 64
$(CORE_LIB64)_SRCS := pwnable_harness.c
$(CORE_LIB64)_DEBUG := true

$(CORE_SERVER)_BITS := 64
$(CORE_SERVER)_SRCS := pwnable_server.c
$(CORE_SERVER)_DEBUG := true
$(CORE_SERVER)_USE_LIBPWNABLEHARNESS := true

ifdef CONFIG_PUBLISH_LIBPWNABLEHARNESS
PUBLISH := $(CORE_LIB64)

ifndef CONFIG_IGNORE_32BIT
PUBLISH := $(PUBLISH) $(CORE_LIB32)
endif #CONFIG_IGNORE_32BIT
endif #CONFIG_PUBLISH_LIBPWNABLEHARNESS


# For use by BaseImage.mk
CORE_TARGETS := $(TARGETS)

# Responsible for building, tagging, and pushing the base PwnableHarness images
include $(CORE_DIR)/BaseImage.mk
