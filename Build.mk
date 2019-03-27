LIB32 := libpwnableharness32.so
LIB64 := libpwnableharness64.so
PWNABLE_SERVER := pwnableserver
PWNABLE_PRELOAD32 := pwnablepreload32.so
PWNABLE_PRELOAD64 := pwnablepreload64.so
TARGETS := $(LIB32) $(LIB64) $(PWNABLE_SERVER) $(PWNABLE_PRELOAD32) $(PWNABLE_PRELOAD64)

CFLAGS := -Wall -Wextra -Wno-unused-parameter -Werror

ASLR := 1
RELRO := 1
CANARY := 1
NX := 1

$(LIB32)_BITS := 32
$(LIB32)_SRCS := pwnable_harness.c
$(LIB32)_DEBUG := 1

$(LIB64)_BITS := 64
$(LIB64)_SRCS := pwnable_harness.c
$(LIB64)_DEBUG := 1

$(PWNABLE_SERVER)_BITS := 64
$(PWNABLE_SERVER)_SRCS := pwnable_server.c
$(PWNABLE_SERVER)_DEBUG := 1
$(PWNABLE_SERVER)_USE_LIBPWNABLEHARNESS := 1

$(PWNABLE_PRELOAD32)_BITS := 32
$(PWNABLE_PRELOAD32)_SRCS := pwnable_preload.c
$(PWNABLE_PRELOAD32)_STRIP := 1

$(PWNABLE_PRELOAD64)_BITS := 64
$(PWNABLE_PRELOAD64)_SRCS := pwnable_preload.c
$(PWNABLE_PRELOAD64)_STRIP := 1

DOCKER_IMAGE := c0deh4cker/pwnableharness

PUBLISH := $(LIB32) $(LIB64)
