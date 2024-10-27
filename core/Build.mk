# This is not intended to be an example Build.mk file to reference.
# Please instead look at examples/stack0/Build.mk for reference.

$(DIR)+THIS_IS_THE_CORE_PROJECT := 1
NO_UNBUFFERED_STDIO := 1

CORE_DIR := $(DIR)
CORE_BUILD := $(BUILD_DIR)

CORE_LIB32 := libpwnableharness32.so
CORE_LIB64 := libpwnableharness64.so
CORE_SERVER := pwnableserver

CFLAGS := -Wall -Wextra -Werror

ASLR := 1
RELRO := 1
CANARY := 1
NX := 1

CORE_TARGETS :=
PUBLISH :=

define core_target_def
CORE_TARGETS-$1 := $1/$$(CORE_LIB64) $1/$$(CORE_SERVER)

$1/$$(CORE_LIB64)_BITS := 64
$1/$$(CORE_LIB64)_SRCS := pwnable_harness.c
$1/$$(CORE_LIB64)_DEBUG := true
$1/$$(CORE_LIB64)_UBUNTU_VERSION := $1

$1/$$(CORE_SERVER)_BITS := 64
$1/$$(CORE_SERVER)_SRCS := pwnable_server.c
$1/$$(CORE_SERVER)_DEBUG := true
$1/$$(CORE_SERVER)_USE_LIBPWNABLEHARNESS := true
$1/$$(CORE_SERVER)_UBUNTU_VERSION := $1

ifndef CONFIG_IGNORE_32BIT
CORE_TARGETS-$1 += $1/$$(CORE_LIB32)

$1/$$(CORE_LIB32)_BITS := 32
$1/$$(CORE_LIB32)_SRCS := pwnable_harness.c
$1/$$(CORE_LIB32)_DEBUG := true
$1/$$(CORE_LIB32)_UBUNTU_VERSION := $1

endif #32bit

CORE_TARGETS += $$(CORE_TARGETS-$1)

ifdef CONFIG_PUBLISH_LIBPWNABLEHARNESS
PUBLISH += $1/$$(CORE_LIB64)

ifndef CONFIG_IGNORE_32BIT
PUBLISH += $1/$$(CORE_LIB32)
endif #CONFIG_IGNORE_32BIT
endif #CONFIG_PUBLISH_LIBPWNABLEHARNESS

endef #core_target_def
$(call generate_ubuntu_versioned_rules,core_target_def)

TARGETS := $(CORE_TARGETS)

# Responsible for building, tagging, and pushing the base PwnableHarness images
ifdef MKDEBUG
$(info Including $(CORE_DIR)/BaseImage.mk)
endif
include $(CORE_DIR)/BaseImage.mk
