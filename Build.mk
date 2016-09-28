LIB32 := libpwnableharness32.so
LIB64 := libpwnableharness64.so
TARGETS := $(LIB32) $(LIB64)
DOCKER_IMAGE := c0deh4cker/pwnableharness

CFLAGS := -Wall -Wextra -Wno-unused-parameter -Werror -fPIC -O0 -ggdb
LDLIBS := # Don't link against ourself

$(LIB32)_BITS := 32
$(LIB64)_BITS := 64
