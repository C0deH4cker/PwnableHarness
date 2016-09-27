LIB32 := libpwnableharness32.so
LIB64 := libpwnableharness64.so
TARGETS := $(LIB32) $(LIB64)
DOCKER_IMAGE := c0deh4cker/pwnableharness

$(LIB32)_BITS := 32
$(LIB32)_CFLAGS := -Wall -Wextra -Wno-unused-parameter -Werror -fPIC -O0 -ggdb
$(LIB32)_LDFLAGS := -shared
$(LIB32)_LDLIBS := # Don't link against ourself

$(LIB64)_BITS := 64
$(LIB64)_CFLAGS := -Wall -Wextra -Wno-unused-parameter -Werror -fPIC -O0 -ggdb
$(LIB64)_LDFLAGS := -shared
$(LIB64)_LDLIBS := # Don't link against ourself
