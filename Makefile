TARGET32 := libpwnable_harness32.so
TARGET64 := libpwnable_harness64.so
TARGETS := $(TARGET32) $(TARGET64)

PREFIX ?= /usr/local
LIBDIR := $(PREFIX)/lib
INCDIR := $(PREFIX)/include
LIBRARIES := $(addprefix $(LIBDIR)/,$(TARGETS))
HEADERS := $(addprefix $(INCDIR)/,$(wildcard *.h))
PRODUCTS := $(LIBRARIES) $(HEADERS)

GCC32 := gcc -m32
CC32 := $(GCC32)
LD32 := $(GCC32)

GCC64 := gcc -m64
CC64 := $(GCC64)
LD64 := $(GCC64)

CFLAGS := -Wall -Wextra -Werror -fPIC -O0 -ggdb
LDFLAGS := -shared

# Setting up source and build paths
BUILD := build
SRCS := $(wildcard *.c)
OBJS32 := $(addprefix $(BUILD)/,$(SRCS:=.32.o))
OBJS64 := $(addprefix $(BUILD)/,$(SRCS:=.64.o))
DEPS := $(OBJS32:.o=.d)

# Print all commands executed when VERBOSE is defined
ifdef VERBOSE
_v :=
else
_v := @
endif


# Default rule
all: $(TARGETS)

# Installation rule
install: $(PRODUCTS)

# Uninstallation rule
uninstall:
	@echo "Uninstalling products"
	$(_v)rm $(PRODUCTS)

# Docker build rule
docker-build: $(TARGETS)
	@echo "Building docker image"
	$(_v)docker build -t c0deh4cker/pwnableharness .

# 32-bit compiler rule
$(BUILD)/%.32.o: % | $(BUILD)/.dir
	@echo "Compiling $<"
	$(_v)$(CC32) $(CFLAGS) -MD -MP -MF $(BUILD)/$*.d -c -o $@ $<

# 64-bit compiler rule
$(BUILD)/%.64.o: % | $(BUILD)/.dir
	@echo "Compiling $<"
	$(_v)$(CC64) $(CFLAGS) -MD -MP -MF $(BUILD)/$*.d -c -o $@ $<

# 32-bit linker rule
$(TARGET32): $(OBJS32)
	@echo "Linking $@"
	$(_v)$(LD32) $(LDFLAGS) -shared -o $@ $^

# 64-bit linker rule
$(TARGET64): $(OBJS64)
	@echo "Linking $@"
	$(_v)$(LD64) $(LDFLAGS) -shared -o $@ $^

# Copy a library to LIBDIR
$(LIBDIR)/%.so: %.so
	@echo "Copying library $@"
	$(_v)cp $< $@

# Copy a header to INCDIR
$(INCDIR)/%.h: %.h
	@echo "Copying header $@"
	$(_v)cp $< $@

# Build dependency rules
-include $(DEPS)


clean:
	@echo "Removing built products"
	$(_v)rm -rf $(BUILD) $(TARGETS)


# Make sure that the .dir files aren't automatically deleted after building
.SECONDARY:

%/.dir:
	$(_v)mkdir -p $* && touch $@

.PHONY: all install uninstall docker-build clean
