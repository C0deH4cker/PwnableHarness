LIB32 := libpwnableharness32.so
LIB64 := libpwnableharness64.so
TARGETS := $(LIB32) $(LIB64)
CFLAGS := -Wall -Wextra -Wno-unused-parameter -Werror -fPIC -ggdb
LDLIBS := none

$(LIB32)_BITS := 32
$(LIB64)_BITS := 64

PUBLISH := $(TARGETS)
DOCKER_IMAGE := c0deh4cker/pwnableharness
