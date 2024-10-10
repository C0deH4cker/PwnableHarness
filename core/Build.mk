# This is not intended to be an example Build.mk file to reference.
# Please instead look at examples/stack0/Build.mk for reference.

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
$$(call pwncc_prepare,$$(CORE_DIR),$1,CORE_PWNCC-$1,CORE_PWNCC_DEPS-$1)

CORE_TARGETS-$1 := $1/$$(CORE_LIB64) $1/$$(CORE_SERVER)

$1/$$(CORE_LIB64)_BITS := 64
$1/$$(CORE_LIB64)_SRCS := pwnable_harness.c
$1/$$(CORE_LIB64)_DEBUG := true
$1/$$(CORE_LIB64)_PWNCC := $$(CORE_PWNCC-$1)
$1/$$(CORE_LIB64)_PWNCC_DEPS := $$(CORE_PWNCC_DEPS-$1)
$1/$$(CORE_LIB64)_PWNCC_DESC := $1

$1/$$(CORE_SERVER)_BITS := 64
$1/$$(CORE_SERVER)_SRCS := pwnable_server.c
$1/$$(CORE_SERVER)_DEBUG := true
$1/$$(CORE_SERVER)_USE_LIBPWNABLEHARNESS := true
$1/$$(CORE_SERVER)_PWNCC := $$(CORE_PWNCC-$1)
$1/$$(CORE_SERVER)_PWNCC_DEPS := $$(CORE_PWNCC_DEPS-$1)
$1/$$(CORE_SERVER)_PWNCC_DESC := $1

ifdef UBUNTU_32BIT_SUPPORT[$1]
CORE_TARGETS-$1 := $$(CORE_TARGETS-$1) $1/$$(CORE_LIB32)

$1/$$(CORE_LIB32)_BITS := 32
$1/$$(CORE_LIB32)_SRCS := pwnable_harness.c
$1/$$(CORE_LIB32)_DEBUG := true
$1/$$(CORE_LIB32)_PWNCC := $$(CORE_PWNCC-$1)
$1/$$(CORE_LIB32)_PWNCC_DEPS := $$(CORE_PWNCC_DEPS-$1)
$1/$$(CORE_LIB32)_PWNCC_DESC := $1

endif #32bit

CORE_TARGETS := $$(CORE_TARGETS) $$(CORE_TARGETS-$1)

ifdef CONFIG_PUBLISH_LIBPWNABLEHARNESS
PUBLISH := $$(PUBLISH) $1/$$(CORE_LIB64)

ifndef CONFIG_IGNORE_32BIT
PUBLISH := $$(PUBLISH) $1/$$(CORE_LIB32)
endif #CONFIG_IGNORE_32BIT
endif #CONFIG_PUBLISH_LIBPWNABLEHARNESS

endef #core_target_def
$(call generate_ubuntu_versioned_rules,core_target_def)

TARGETS := $(CORE_TARGETS)

# Responsible for building, tagging, and pushing the base PwnableHarness images
include $(CORE_DIR)/BaseImage.mk
