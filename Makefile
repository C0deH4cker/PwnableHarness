TARGETS := stack0

GCC := gcc -m32
CC := $(GCC)
LD := $(GCC)

GCC64 := gcc -m64
CC64 := $(GCC64)
LD64 := $(GCC64)

OBJCOPY := objcopy --strip-unneeded
OBJCOPY_DESC := Stripping

CFLAGS := -O0 -I.
LDFLAGS :=

WEB_DIR := /usr/share/nginx/ctf

# User's home directory is /ctf/<chall> so they chroot there and chdir to their chrooted home directory
CHROOT = /ctf/$*
SVCDIR = $(CHROOT)/ctf/$*

# This is a macro that will apply the given rule to all targets
routine = $(patsubst %,$1[%],$(TARGETS))

# Setting up source and build paths
BUILD := build
SRC_DIRS := $(addsuffix _src,$(TARGETS))
SRCS := $(foreach d,$(SRC_DIRS),$(wildcard $d/*.c))
OBJS := $(addprefix $(BUILD)/,$(SRCS:.c=.o))
DEPS := $(OBJS:.o=.d)
BUILD_DIRS := $(BUILD) $(addprefix $(BUILD)/,$(SRC_DIRS))
BUILD_DIR_RULES := $(addsuffix /.dir,$(BUILD_DIRS))

# Print all commands executed when VERBOSE is defined
ifdef VERBOSE
_v :=
else
_v := @
endif


# Default rule
all: $(TARGETS)

# Debug build (build with debug symbols and don't strip any symbols)
debug: CFLAGS += -ggdb -DDEBUG=1 -UNDEBUG
debug: OBJCOPY := cp
debug: OBJCOPY_DESC := Copying
debug: $(TARGETS)

# Target specific overrides
stack0: CFLAGS += -fno-stack-protector
stack0: LDFLAGS += -Wl,-z,execstack

# Special cased compile rule for the harness to build it once per target
$(BUILD)/%_src/harness.o: harness.c | $(BUILD_DIR_RULES)
	@echo "Compiling $< for $*"
	$(_v)$(CC) $(CFLAGS) -MD -MP -MF $(BUILD)/$*_src/harness.d -c -o $@ $<

# Generic compile rule
$(BUILD)/%.o: %.c | $(BUILD_DIR_RULES)
	@echo "Compiling $<"
	$(_v)$(CC) $(CFLAGS) -MD -MP -MF $(BUILD)/$*.d -c -o $@ $<

# Build dependency rules
-include $(DEPS)

# Strip rule that produces the final product
$(TARGETS): %: $(BUILD)/%.raw
	@echo "$(OBJCOPY_DESC) $@"
	$(_v)$(OBJCOPY) $< $@


# Macro that selects the object files from OBJS that belong to the specified target
target_objs = $(filter $(BUILD)/$1_src/%,$(OBJS))

# Macro that defines a linker rule when called
define make_link_rule
$(BUILD)/$1.raw: $(BUILD)/$1_src/harness.o $(call target_objs,$1)
	@echo "Linking $1"
	$$(_v)$$(LD) $$(LDFLAGS) -o $$@ $$^
endef

# Produce a linker rule for each target
$(foreach target,$(TARGETS),$(eval $(call make_link_rule,$(target))))


# Routine stubs for controlling services
install: $(call routine,install)

uninstall: $(call routine,uninstall)

publish: $(call routine,publish)

unpublish: $(call routine,unpublish)

start: $(call routine,start)

stop: $(call routine,stop)

restart: $(call routine,restart)

# Routine implementations for controlling services
install[%]: %
	@echo "Installing $* service"
	$(_v)install -o root -g root -m 4750 $* $(SVCDIR)/

uninstall[%]: stop[%]
	@echo "Uninstalling $* service"
	$(_v)rm $(SVCDIR)/$*

publish[%]: %
	@echo "Publishing $* to web server"
	$(_v)install -o www-data -g www-data -m 0775 -d $(WEB_DIR)/$*
	$(_v)install -o www-data -g www-data -m 0664 $* $*_src/* $(WEB_DIR)/$*/

unpublish[%]: %
	@echo "Unpublishing $* from web server"
	$(_v)rm -rf $(WEB_DIR)/$**

start[%]: stop[%]
	@echo "Starting $* as a daemonized screen session"
	$(_v)screen -dmS $* $(SVCDIR)/$*

stop[%]:
	@echo "Stopping $* service"
	$(_v)killall -9 $* ||:

restart[%]: start[%]
	@true

clean:
	@echo "Removing built products"
	$(_v)rm -rf $(BUILD) $(TARGETS)


# Make sure that the .dir files aren't automatically deleted after building
.SECONDARY:

%/.dir:
	$(_v)mkdir -p $* && touch $@

.PHONY: all clean install uninstall publish unpublish start stop restart
