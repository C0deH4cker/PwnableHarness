# Naming convention for macros declared here:
#
# Macros named with a leading underscore must be eval-ed after calling them,
# whereas those without a leading underscore do not. Whenever a macro that
# requires eval-ing is defined, both macros with and without the leading
# underscore are defined, where the one without is defined as eval-ing the
# underscore-prefixed version.
#
# For example, macro named _make_rule must be called using:
# $(eval $(call _make_rule,args...))
# whereas a macro named make_rule must be called using:
# $(call make_rule,args)
# Also, when both forms are present, make_rule is defined like so:
# make_rule = $(eval $(call _make_rule,args...))
# In this way, _make_rule is recursively expanded in the call context and
# therefore has access to the parameter variables $1, $2, etc that come
# from calling make_rule.
#
# Because the only difference between the two forms is that the one without
# the leading underscore is eval-ed, when defining such a macro that needs
# to call other macros, call the non-eval-ed version. That prevents double
# evaluation, since otherwise the macro will be evaluated when it is called
# and again when the calling macro is eval-ed.


# Set defaults
ifndef DEFAULT_BITS
DEFAULT_BITS := 64
endif

ifndef DEFAULT_CPPFLAGS
DEFAULT_CPPFLAGS :=
endif

ifndef DEFAULT_CFLAGS
DEFAULT_CFLAGS :=
endif

ifndef DEFAULT_CXXFLAGS
DEFAULT_CXXFLAGS :=
endif

ifndef DEFAULT_OFLAGS
DEFAULT_OFLAGS := -O0
endif

ifndef DEFAULT_ASFLAGS
DEFAULT_ASFLAGS :=
endif

ifndef DEFAULT_LDFLAGS
DEFAULT_LDFLAGS :=
endif

ifndef DEFAULT_CC
DEFAULT_CC := gcc
endif

ifndef DEFAULT_CXX
DEFAULT_CXX := g++
endif

ifndef DEFAULT_AS
DEFAULT_AS := gcc
endif

ifndef DEFAULT_LD
DEFAULT_LD :=
endif

ifndef DEFAULT_AR
DEFAULT_AR := ar
endif

ifndef DEFAULT_RELRO
DEFAULT_RELRO := 0
endif

ifndef DEFAULT_CANARY
DEFAULT_CANARY := none
endif

ifndef DEFAULT_NX
DEFAULT_NX := 0
endif

ifndef DEFAULT_PIE
DEFAULT_PIE :=
endif

ifndef DEFAULT_ASLR
DEFAULT_ASLR :=
endif

ifndef DEFAULT_STRIP
DEFAULT_STRIP := 0
endif

ifndef DEFAULT_DEBUG
DEFAULT_DEBUG := 0
endif

ifndef DEFAULT_UBUNTU_VERSION
DEFAULT_UBUNTU_VERSION := 24.04
endif

ifndef DEFAULT_DOCKER_CPULIMIT
# Default to half of a virtual CPU core
DEFAULT_DOCKER_CPULIMIT := 0.5
endif

ifndef DEFAULT_DOCKER_MEMLIMIT
# Default to 500MB of RAM usage total
# This can be measured with `docker stats <container>`. As a baseline, I
# checked a basic challenge. It uses 3.2MB when sitting idle without any
# connections, then jumps to 5.8MB with an active connection. That's 2.6MB
# per connection (for a basic challenge). If we overestimate this to 10MB
# per connection and want to support 50 concurrent connections, this gives
# us 500MB. Challenges that need more memory can of course override this
# default by setting `DOCKER_MEMLIMIT`.
DEFAULT_DOCKER_MEMLIMIT := 500m
endif

ifndef DEFAULT_DOCKER_TIMELIMIT
DEFAULT_DOCKER_TIMELIMIT :=
endif

ifndef DEFAULT_DOCKER_PASSWORD
DEFAULT_DOCKER_PASSWORD :=
endif


# Any of these values indicate that a variable is "true"
TRUE_VALUES  := 1 true  True  TRUE  yes y Yes Y YES on  On  ON

# Any of these values indicate that a variable is "false"
FALSE_VALUES := 0 false False FALSE no  n No  N NO  off Off OFF

# Returns 1 when $1 is an empty string
is_value_empty = $(if $1,,1)

# Returns 1 when $1 is in $(TRUE_VALUES)
is_value_true = $(if $(filter $1,$(TRUE_VALUES)),1)

# Returns 1 when $1 is in $(FALSE_VALUES)
is_value_false = $(if $(filter $1,$(FALSE_VALUES)),1)

# Returns 1 when $1 names an undefined variable
is_var_undefined = $(if $(filter $(origin $1),undefined),1)

# Returns 1 when $1 names a defined variable
is_var_defined = $(if $(call is_var_undefined,$1),,1)

# Returns 1 when $1 names a variable whose value is in $(TRUE_VALUES)
is_var_true = $(and $(call is_var_defined,$1),$(call is_value_true,$($1)))

# Returns 1 when $1 names a variable whose value is in $(FALSE_VALUES)
is_var_false = $(and $(call is_var_defined,$1),$(call is_value_false,$($1)))

# Returns 1 when $1 names an undefined variable or when $1's value is the empty string or in $(FALSE_VALUES)
is_var_false_or_undefined = $(or $(call is_var_undefined,$1),$(call is_value_empty,$($1)),$(call is_value_false,$($1)))


#####
# generate_target($1: subdirectory, $2: target)
#
# Generate the rules to build the given target contained within the given directory.
#####
define _generate_target
ifdef MKDEBUG
$$(info Generating target rules for $1+$2)
endif
ifdef MKTRACE
$$(info Tracing _generate_target($1,$2)...)
endif #MKTRACE

# Product path
ifeq "$$(origin $2_PRODUCT)" "undefined"
$2_PRODUCT := $$(or $$($1+PRODUCT),$$($1+BUILD)/$2)
endif

# Ensure that target_BITS has a value, default to 32-bits
ifeq "$$(origin $2_BITS)" "undefined"
$2_BITS := $$($1+BITS)
endif

# Check that BITS doesn't conflict with CONFIG_IGNORE_32BIT
ifndef $1+THIS_IS_THE_CORE_PROJECT
ifeq "$$($2_BITS)" "32"
ifdef CONFIG_IGNORE_32BIT
$$(error $1/$2: Requesting 32-bit binaries, but CONFIG_IGNORE_32BIT is set!)
endif #CONFIG_IGNORE_32BIT
endif #BITS==32
endif #THIS_IS_THE_CORE_PROJECT

ifeq "$$(origin $2_NO_EXTRA_FLAGS)" "undefined"
$2_NO_EXTRA_FLAGS := $$($1+NO_EXTRA_FLAGS)
endif

# Ensure that target_CPPFLAGS is defined
ifeq "$$(origin $2_CPPFLAGS)" "undefined"
$2_CPPFLAGS := $$($1+CPPFLAGS)
endif
ifeq "$$(origin $2_NO_EXTRA_CPPFLAGS)" "undefined"
$2_NO_EXTRA_CPPFLAGS := $$(or $$($2_NO_EXTRA_FLAGS),$$($1+NO_EXTRA_CPPFLAGS))
endif
$2_EXTRA_CPPFLAGS :=


# Ensure that target_CFLAGS is defined
ifeq "$$(origin $2_CFLAGS)" "undefined"
$2_CFLAGS := $$($1+CFLAGS)
endif
ifeq "$$(origin $2_NO_EXTRA_CFLAGS)" "undefined"
$2_NO_EXTRA_CFLAGS := $$(or $$($2_NO_EXTRA_FLAGS),$$($1+NO_EXTRA_CFLAGS))
endif
$2_EXTRA_CFLAGS :=

# Ensure that target_CXXFLAGS is defined
ifeq "$$(origin $2_CXXFLAGS)" "undefined"
$2_CXXFLAGS := $$($1+CXXFLAGS)
endif
ifeq "$$(origin $2_NO_EXTRA_CXXFLAGS)" "undefined"
$2_NO_EXTRA_CXXFLAGS := $$(or $$($2_NO_EXTRA_FLAGS),$$($1+NO_EXTRA_CXXFLAGS))
endif
$2_EXTRA_CXXFLAGS :=

# Ensure that target_OFLAGS has a value, default to no optimization
ifeq "$$(origin $2_OFLAGS)" "undefined"
$2_OFLAGS := $$($1+OFLAGS)
endif
ifeq "$$(origin $2_NO_EXTRA_OFLAGS)" "undefined"
$2_NO_EXTRA_OFLAGS := $$(or $$($2_NO_EXTRA_FLAGS),$$($1+NO_EXTRA_OFLAGS))
endif
$2_EXTRA_OFLAGS :=

# Ensure that target_ASFLAGS is defined
ifeq "$$(origin $2_ASFLAGS)" "undefined"
$2_ASFLAGS := $$($1+ASFLAGS)
endif
ifeq "$$(origin $2_NO_EXTRA_ASFLAGS)" "undefined"
$2_NO_EXTRA_ASFLAGS := $$(or $$($2_NO_EXTRA_FLAGS),$$($1+NO_EXTRA_ASFLAGS))
endif
$2_EXTRA_ASFLAGS := -D__ASSEMBLY__

# Ensure that target_LDFLAGS is defined
ifeq "$$(origin $2_LDFLAGS)" "undefined"
$2_LDFLAGS := $$($1+LDFLAGS)
endif
ifeq "$$(origin $2_NO_EXTRA_LDFLAGS)" "undefined"
$2_NO_EXTRA_LDFLAGS := $$(or $$($2_NO_EXTRA_FLAGS),$$($1+NO_EXTRA_LDFLAGS))
endif
$2_EXTRA_LDFLAGS :=

# Ensure that target_SRCS has a value, default to searching for all C and
# C++ sources in the same directory as Build.mk.
ifeq "$$(origin $2_SRCS)" "undefined"
$2_SRCS := $$($1+SRCS)
else
# Prefix each item with the project directory
$2_SRCS := $$(addprefix $1/,$$($2_SRCS))
endif

# Ensure that target_OBJS_DIR has a value, defaulting to .build/proj/target_objs
ifeq "$$(origin $2_OBJS_DIR)" "undefined"
$2_OBJS_DIR := $$($1+BUILD)/$2_objs
endif

# Ensure that target_OBJS has a value, default to modifying the value of each
# src from target_SRCS into target_BUILD/src.o
# Example: generate_target(proj, target) with main.cpp -> .build/proj/target_objs/main.cpp.o
ifeq "$$(origin $2_OBJS)" "undefined"
$2_OBJS := $$(patsubst $1/%,$$($2_OBJS_DIR)/%.o,$$($2_SRCS))
endif

# Ensure that target_DEPS has a value, default to the value of target_OBJS
# but with .o extensions replaced with .d.
ifeq "$$(origin $2_DEPS)" "undefined"
$2_DEPS := $$($2_OBJS:.o=.d)
endif

# Ensure that target_CC has a value
ifeq "$$(origin $2_CC)" "undefined"
$2_CC := $$($1+CC)
endif

# Ensure that target_CXX has a value
ifeq "$$(origin $2_CXX)" "undefined"
$2_CXX := $$($1+CXX)
endif

# Ensure that target_AS has a value
ifeq "$$(origin $2_AS)" "undefined"
$2_AS := $$($1+AS)
endif

# Ensure that target_LD has a value, defaulting to target_CC unless there are
# C++ sources, in which case target_CXX is used instead
ifeq "$$(origin $2_LD)" "undefined"
$2_LD := $$(or $$($1+LD),$$(if $$(filter %.cpp,$$($2_SRCS)),$$($2_CXX),$$($2_CC)))
endif

# Ensure that target_AR has a value
ifeq "$$(origin $2_AR)" "undefined"
$2_AR := $$($1+AR)
endif

ifeq "$$(origin $2_UBUNTU_VERSION)" "undefined"
$2_UBUNTU_VERSION := $$($1+UBUNTU_VERSION)
endif

# Define UBUNTU_VERSION_NUMBER as the numeric version for Ubuntu (even when UBUNTU_VERSION is the named alias)
ifdef UBUNTU_VERSION_TO_ALIAS[$$($2_UBUNTU_VERSION)]
$2_UBUNTU_VERSION_NUMBER := $$($2_UBUNTU_VERSION)
else ifdef UBUNTU_ALIAS_TO_VERSION[$$($2_UBUNTU_VERSION)]
$2_UBUNTU_VERSION_NUMBER := $$(UBUNTU_ALIAS_TO_VERSION[$$($2_UBUNTU_VERSION)])
else
$$(error Unknown Ubuntu version in $1/$2: "$$($2_UBUNTU_VERSION)")
endif

# Split Ubuntu version number into major, minor, and int. 24.04 -> major=24, minor=04, int=2404
$2_UBUNTU_VERSION_PARTS := $$(subst .,$$(SPACE),$$($2_UBUNTU_VERSION_NUMBER))
$2_UBUNTU_VERSION_MAJOR := $$(firstword $$($2_UBUNTU_VERSION_PARTS))
$2_UBUNTU_VERSION_MINOR := $$(word 2,$$($2_UBUNTU_VERSION_PARTS))
$2_UBUNTU_VERSION_INT := $$($2_UBUNTU_VERSION_MAJOR)$$($2_UBUNTU_VERSION_MINOR)

# Run compiler commands in a pwncc container?
$2_PWNCC :=
$2_PWNCC_DEPS :=
$2_PWNCC_DESC :=
ifdef CONFIG_USE_PWNCC
$$(call pwncc_prepare,$1,$$($2_UBUNTU_VERSION),$2_PWNCC,$2_PWNCC_DEPS)
# Format string for a printed message prefix
$2_PWNCC_DESC := [$$($2_UBUNTU_VERSION)]$$(SPACE)
endif #CONFIG_USE_PWNCC

# Ensure that target_BINTYPE has a value, defaulting to "dynamiclib" if target
# name ends in ".so" otherwise "executable".
ifeq "$$(origin $2_BINTYPE)" "undefined"
ifdef $1+BINTYPE
$2_BINTYPE := $$($1+BINTYPE)
else ifeq "$$(suffix $2)" ".so"
$2_BINTYPE := dynamiclib
else ifeq "$$(suffix $2)" ".a"
$2_BINTYPE := staticlib
else #BINTYPE & suffix .so/a
$2_BINTYPE := executable
endif #BINTYPE & suffix .so/a
endif #target_BINTYPE undefined

# Ensure that target_LIBS has a value
ifeq "$$(origin $2_LIBS)" "undefined"
$2_LIBS := $$($1+LIBS)
endif #target_LIBS undefined

# Ensure that target_USE_LIBPWNABLEHARNESS has a value
ifeq "$$(origin $2_USE_LIBPWNABLEHARNESS)" "undefined"
$2_USE_LIBPWNABLEHARNESS := $$($1+USE_LIBPWNABLEHARNESS)
endif

# Ensure that target_NO_UNBUFFERED_STDIO has a value
ifeq "$$(origin $2_NO_UNBUFFERED_STDIO)" "undefined"
$2_NO_UNBUFFERED_STDIO := $$($1+NO_UNBUFFERED_STDIO)
endif

# Ensure that target_NO_RPATH has a value
ifeq "$$(origin $2_NO_RPATH)" "undefined"
$2_NO_RPATH := $$($1+NO_RPATH)
endif

# Ensure that target_LDLIBS has a value
ifeq "$$(origin $2_LDLIBS)" "undefined"
$2_LDLIBS := $$($1+LDLIBS)
endif #target_LDLIBS undefined

# Add dependency on libpwnableharness(32|64).so if requested
ifdef $2_USE_LIBPWNABLEHARNESS
$2_ALLLIBS := $$($2_LIBS) $$(BUILD)/core/$$($2_UBUNTU_VERSION_NUMBER)/libpwnableharness$$($2_BITS).so

# When not building PwnableHarness core, just extract the prebuilt libpwnableharness*.so library out of the Docker image
ifndef $1+THIS_IS_THE_CORE_PROJECT
ifndef DEFINED_GRAB_LIBPWNABLEHARNESS$$($2_BITS)_$$($2_UBUNTU_VERSION_NUMBER)
DEFINED_GRAB_LIBPWNABLEHARNESS$$($2_BITS)_$$($2_UBUNTU_VERSION_NUMBER) := 1
$$(BUILD)/core/$$($2_UBUNTU_VERSION_NUMBER)/libpwnableharness$$($2_BITS).so:
	$$(_V)echo "Pulling $$($1+DOCKER_FULL_BASE) (if necessary)"
	$$(_v)$$(DOCKER) pull $$($1+DOCKER_PLATFORM) $$($1+DOCKER_FULL_BASE)
	$$(_V)echo "Copying libpwnableharness$$($2_BITS).so from $$($1+DOCKER_FULL_BASE)"
	$$(_v)mkdir -p $$(@D) && $$(DOCKER) run $$($1+DOCKER_PLATFORM) --rm --entrypoint /bin/cat $$($1+DOCKER_FULL_BASE) /usr/lib/libpwnableharness$$($2_BITS).so > $$@

endif #DEFINED_GRAB_LIBPWNABLEHARNESS
ifndef DEFINED_CLEAN_LIBPWNABLEHARNESS_$$($2_UBUNTU_VERSION_NUMBER)
DEFINED_CLEAN_LIBPWNABLEHARNESS_$$($2_UBUNTU_VERSION_NUMBER) := 1

clean: clean-libpwnableharness-$$($2_UBUNTU_VERSION_NUMBER)
.PHONY: clean-libpwnableharness-$$($2_UBUNTU_VERSION_NUMBER)
clean-libpwnableharness-$$($2_UBUNTU_VERSION_NUMBER):
	$$(_v)rm -rf $$(BUILD)/core/$$($2_UBUNTU_VERSION_NUMBER)

endif #DEFINED_CLEAN_LIBPWNABLEHARNESS
endif #THIS_IS_THE_CORE_PROJECT

else #USE_LIBPWNABLEHARNESS
$2_ALLLIBS := $$($2_LIBS)
endif #USE_LIBPWNABLEHARNESS

# Allow loading shared libraries from the executable directory
ifeq "1" "$$(call is_var_false_or_undefined,$2_NO_RPATH)"
ifdef IS_LINUX
$2_EXTRA_LDFLAGS += -Wl,-rpath,`printf "\044"`ORIGIN -Wl,-z,origin
else ifdef IS_MAC
$2_EXTRA_LDFLAGS += -Wl,-rpath,@executable_path
endif #IS_LINUX/IS_MAC
endif #NO_RPATH

# On macOS, dylibs need an "install name" to allow them to be loaded from the
# executable's directory
ifeq "$$($2_BINTYPE)" "dynamiclib"
ifdef IS_MAC
$2_EXTRA_LDFLAGS += -install_name @rpath/$2
endif #IS_MAC
endif #dynamiclib

# Convert a list of dynamic library names into linker arguments
ifdef IS_LINUX
$2_LIBPATHS := $$(sort $$(patsubst %/,%,$$(dir $$($2_ALLLIBS))))
$2_EXTRA_LDFLAGS += $$(addprefix -L,$$($2_LIBPATHS))
$2_LDLIBS += $$(addprefix -l:,$$(notdir $$($2_ALLLIBS)))
else ifdef IS_MAC
$2_LDLIBS += $$($2_ALLLIBS)
endif


## Hardening flags

# Ensure that target_RELRO has a value
ifeq "$$(origin $2_RELRO)" "undefined"
$2_RELRO := $$($1+RELRO)
endif

# Ensure that target_CANARY has a value
ifeq "$$(origin $2_CANARY)" "undefined"
$2_CANARY := $$($1+CANARY)
endif

# Ensure that target_NX has a value
ifeq "$$(origin $2_NX)" "undefined"
$2_NX := $$($1+NX)
endif

# Ensure that target_PIE has a value
ifeq "$$(origin $2_PIE)" "undefined"
$2_PIE := $$($1+PIE)
endif

# Ensure that target_ASLR has a value
ifeq "$$(origin $2_ASLR)" "undefined"
$2_ASLR := $$($1+ASLR)
endif

# Ensure that target_STRIP has a value
ifeq "$$(origin $2_STRIP)" "undefined"
$2_STRIP := $$($1+STRIP)
endif

# Ensure that target_DEBUG has a value
ifeq "$$(origin $2_DEBUG)" "undefined"
$2_DEBUG := $$($1+DEBUG)
endif


## Apply hardening flags

# RELRO (Read-only relocations), only works on Linux
ifdef IS_LINUX
ifeq "1" "$$(call is_var_false_or_undefined,$2_RELRO)"
$2_EXTRA_LDFLAGS += -Wl,-z,norelro
else ifeq "1" "$$(call is_var_true,$2_RELRO)"
$2_EXTRA_LDFLAGS += -Wl,-z,relro,-z,now
else ifeq "" "$$(filter $$($2_RELRO),partial default)"
# Nothing
else #RELRO
$$(error Unknown value for RELRO in $1/$2: "$$($2_RELRO)". Possible values: 0 1 partial default)
endif #RELRO
endif #IS_LINUX

# Map user-provided value of CANARY to a valid value
ifeq "1" "$$(call is_var_false_or_undefined,$2_CANARY)"
# False-ish values
$2_CANARY := none
else ifeq "1" "$$(call is_var_true,$2_CANARY)"
# True-ish values imply strong (except gcc in Ubuntu <= 14.04 doesn't support that)
# Just use "all" for now: https://github.com/C0deH4cker/PwnableHarness/issues/54
$2_CANARY := all
else ifeq "" "$$(filter $$($2_CANARY),all strong explicit normal default none)"
$$(error Unknown value for CANARY in $1/$2: "$$($2_CANARY)". Possible values: all strong explicit normal default none)
endif #CANARY

# Apply CANARY setting to flags
ifeq "$$($2_CANARY)" "all"
$2_CANARY_FLAG := -fstack-protector-all
else ifeq "$$($2_CANARY)" "strong"
$2_CANARY_FLAG := -fstack-protector-strong
else ifeq "$$($2_CANARY)" "explicit"
$2_CANARY_FLAG := -fstack-protector-explicit
else ifeq "$$($2_CANARY)" "normal"
$2_CANARY_FLAG := -fstack-protector
else ifeq "$$($2_CANARY)" "default"
# Nothing
$2_CANARY_FLAG :=
else ifeq "$$($2_CANARY)" "none"
$2_CANARY_FLAG := -fno-stack-protector
endif #CANARY
$2_CFLAGS += $$($2_CANARY_FLAG)
$2_CXXFLAGS += $$($2_CANARY_FLAG)

# NX (No Execute) aka DEP (Data Execution Prevention) aka W^X (Write XOR eXecute)
ifeq "1" "$$(call is_var_false_or_undefined,$2_NX)"
ifdef IS_LINUX
$2_EXTRA_LDFLAGS += -z execstack
else ifdef IS_MAC
$2_EXTRA_LDFLAGS += -Wl,-allow_stack_execute
endif #OS
else ifeq "1" "$$(call is_var_true,$2_NX)"
ifdef IS_LINUX
$2_EXTRA_LDFLAGS += -z noexecstack
else ifdef IS_MAC
# No option, default is stack isn't executable
endif #OS
else ifeq "$$($2_NX)" "default"
# Nothing
else #NX
$$(error Unknown value for NX in $1/$2: "$$($2_NX)". Possible values: 0 1 default)
endif #NX

# PIE is an alias for ASLR
ifdef $2_PIE
ifdef $2_ASLR
$$(error Both ASLR and PIE are defined! Pick one.)
endif #ASLR
$2_ASLR := $$($2_PIE)
$2_ASLR_VAR := PIE
else #PIE
$2_ASLR_VAR := ASLR
endif #PIE

# ASLR (Address Space Layout Randomization)
ifeq "1" "$$(call is_var_false_or_undefined,$2_ASLR)"
ifeq "$$($2_BINTYPE)" "executable"
ifdef IS_LINUX
$2_EXTRA_LDFLAGS += -no-pie
else ifdef IS_MAC
$2_EXTRA_LDFLAGS += -Wl,-no_pie
endif #IS_LINUX/IS_MAC
endif #executable
else ifeq "$$($2_ASLR)" "default"
# Nothing
else ifeq "1" "$$(call is_var_true,$2_ASLR)"
ifeq "$$($2_BINTYPE)" "executable"
$2_EXTRA_CFLAGS += -fPIE
$2_EXTRA_CXXFLAGS += -fPIE
ifdef IS_LINUX
$2_EXTRA_LDFLAGS += -pie
else ifdef IS_MAC
$2_EXTRA_LDFLAGS += -Wl,-pie
endif #IS_LINUX/IS_MAC
else #executable
$2_EXTRA_CFLAGS += -fPIC
$2_EXTRA_CXXFLAGS += -fPIC
endif #executable
else #ASLR
$$(error Unknown value for $$($2_ASLR_VAR) in $1/$2: "$$($2_ASLR)". Possible values: 0 1 default)
endif #ASLR

# Strip symbols
ifeq "1" "$$(call is_var_true,$2_STRIP)"
ifdef IS_LINUX
$2_EXTRA_LDFLAGS += -Wl,-s
else ifdef IS_MAC
$2_EXTRA_LDFLAGS += -Wl,-S,-x
endif #IS_LINUX/IS_MAC
endif #STRIP

# Debug symbols
ifeq "1" "$$(call is_var_false_or_undefined,$2_DEBUG)"
$2_EXTRA_CPPFLAGS += -DNDEBUG=1 -UDEBUG
else ifeq "$$($2_DEBUG)" "default"
# Nothing
else #DEBUG
$2_EXTRA_CPPFLAGS += -DDEBUG=1 -UNDEBUG
ifeq "1" "$$(call is_var_true,$2_DEBUG)"
$2_EXTRA_OFLAGS += -ggdb
else #!is_true(DEBUG)
$2_EXTRA_OFLAGS += $$($2_DEBUG)
endif #!is_true(DEBUG)
endif #DEBUG

# Add project directory to include path
$2_EXTRA_CPPFLAGS += -I$1

# Combine user-provided flags with PwnableHarness-generated flags
$2_ALL_CPPFLAGS := $$(if $$($2_NO_EXTRA_CPPFLAGS),,$$($2_EXTRA_CPPFLAGS) )$$($2_CPPFLAGS)
$2_ALL_ASFLAGS  := $$(if $$($2_NO_EXTRA_ASFLAGS),,$$($2_EXTRA_ASFLAGS) )$$($2_ASFLAGS)
$2_ALL_CFLAGS   := $$(if $$($2_NO_EXTRA_CFLAGS),,$$($2_EXTRA_CFLAGS) )$$($2_CFLAGS)
$2_ALL_CXXFLAGS := $$(if $$($2_NO_EXTRA_CXXFLAGS),,$$($2_EXTRA_CXXFLAGS) )$$($2_CXXFLAGS)
$2_ALL_OFLAGS   := $$(if $$($2_NO_EXTRA_OFLAGS),,$$($2_EXTRA_OFLAGS) )$$($2_OFLAGS)
$2_ALL_LDFLAGS  := $$(if $$($2_NO_EXTRA_LDFLAGS),,$$($2_EXTRA_LDFLAGS) )$$($2_LDFLAGS)

ifeq "$$($2_BINTYPE)" "executable"
# Build and link in the stdio_unbuffer.c source file unless opted out
ifndef $2_NO_UNBUFFERED_STDIO
$2_OBJS += $$($1+BUILD)/$2_objs/stdio_unbuffer.o

ifdef MKTRACE
$$(info Adding rule for $1+$2's stdio_unbuffer.o)
endif #MKTRACE

ifndef UNBUFFER_DIR
ifdef CONTAINER_BUILD
UNBUFFER_DIR := $$(BUILD)/core

# Copy from pwnmake's ROOT_DIR to the workspace's .build directory. This is done
# so that the pwncc image is able to access it (as it can't access files in the
# pwnmake image).
$$(UNBUFFER_DIR)/stdio_unbuffer.c: $$(ROOT_DIR)/stdio_unbuffer.c | $$(UNBUFFER_DIR)/.dir
	$$(_v)cp $$< $$@

clean: clean-unbuffer
.PHONY: clean-unbuffer
clean-unbuffer:
	$$(_v)rm -f $$(UNBUFFER_DIR)/stdio_unbuffer.c

else #CONTAINER_BUILD
UNBUFFER_DIR := $$(ROOT_DIR)
endif #CONTAINER_BUILD
endif #UNBUFFER_DIR

# Compiler rule for stdio_unbuffer.o
$$($1+BUILD)/$2_objs/stdio_unbuffer.o: $$(UNBUFFER_DIR)/stdio_unbuffer.c | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Compiling $$(<F) for $1/$2"
	$$(_v)$$($2_PWNCC)$$($2_CC) -m$$($2_BITS) $$($2_ALL_CPPFLAGS) $$($2_ALL_CFLAGS) $$($2_ALL_OFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

endif #NO_UNBUFFERED_STDIO
endif #BINTYPE == executable

ifdef MKTRACE
$$(info Adding build deps for $1+$2)
endif #MKTRACE

# Ensure directories are created for all object files
$2_OBJ_DIR_RULES := $$(addsuffix /.dir,$$(sort $$(patsubst %/,%,$$(dir $$($2_OBJS)))))
$$($2_OBJS): $$($2_OBJ_DIR_RULES)

# Rebuild all build products when the Build.mk is modified
$$($2_OBJS): $$($1+BUILD_MK) $$(ROOT_DIR)/Macros.mk
$$($2_PRODUCT): $$($1+BUILD_MK) $$(ROOT_DIR)/Macros.mk


ifdef MKTRACE
$$(info Adding compiler rules for $1+$2)
endif #MKTRACE

# Compiler rule for C sources
$$(filter %.c.o,$$($2_OBJS)): $$($1+BUILD)/$2_objs/%.c.o: $1/%.c | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Compiling $$<"
	$$(_v)$$($2_PWNCC)$$($2_CC) -m$$($2_BITS) $$($2_ALL_CPPFLAGS) $$($2_ALL_CFLAGS) $$($2_ALL_OFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Compiler rule for C++ sources
$$(filter %.cpp.o,$$($2_OBJS)): $$($1+BUILD)/$2_objs/%.cpp.o: $1/%.cpp | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Compiling $$<"
	$$(_v)$$($2_PWNCC)$$($2_CXX) -m$$($2_BITS) $$($2_ALL_CPPFLAGS) $$($2_ALL_CXXFLAGS) $$($2_ALL_OFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

# Assembler rule
$$(filter %.S.o,$$($2_OBJS)): $$($1+BUILD)/$2_objs/%.S.o: $1/%.S | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Assembling $$<"
	$$(_v)$$($2_PWNCC)$$($2_AS) -m$$($2_BITS) $$($2_ALL_CPPFLAGS) $$($2_ALL_ASFLAGS) -MD -MP -MF $$(@:.o=.d) -c -o $$@ $$<

clean-one[$1]: clean-objs[$1+$2]

$$(call add_phony_target,clean-objs[$1+$2])
clean-objs[$1+$2]:
	$$(_v)rm -rf $$($2_OBJS_DIR)

ifdef MKTRACE
$$(info Including dependency files for $1+$2)
endif #MKTRACE

# Compilation dependency rules
-include $$($2_DEPS)

$2_PRODUCT_DIR_RULE := $$(patsubst %/,%,$$(dir $$($2_PRODUCT)))/.dir


ifdef MKTRACE
$$(info Adding linker rules for $1+$2)
endif #MKTRACE

ifeq "$$($2_BINTYPE)" "executable"
# Linker rule to produce the final target (specialization for executables)
$$($2_PRODUCT): $$($2_OBJS) $$($2_ALLLIBS) $$($2_PRODUCT_DIR_RULE) | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Linking executable $$@"
	$$(_v)$$($2_PWNCC)$$($2_LD) -m$$($2_BITS) $$($2_ALL_OFLAGS) $$($2_ALL_LDFLAGS) \
		-o $$@ $$($2_OBJS) $$($2_LDLIBS)

else ifeq "$$($2_BINTYPE)" "dynamiclib"
# Linker rule to produce the final target (specialization for shared libraries)
$$($2_PRODUCT): $$($2_OBJS) $$($2_ALLLIBS) $$($2_PRODUCT_DIR_RULE) | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Linking shared library $$@"
	$$(_v)$$($2_PWNCC)$$($2_LD) -m$$($2_BITS) -shared $$($2_ALL_OFLAGS) $$($2_ALL_LDFLAGS) \
		-o $$@ $$($2_OBJS) $$($2_LDLIBS)

else ifeq "$$($2_BINTYPE)" "staticlib"
# Archive rule to produce the final target (specialication for static libraries)
$$($2_PRODUCT): $$($2_OBJS) $$($2_PRODUCT_DIR_RULE) | $$($2_PWNCC_DEPS)
	$$(_V)echo "$$($2_PWNCC_DESC)Archiving static library $$@"
	$$(_v)$$($2_PWNCC)$$($2_AR) rcs $$@ $$^

else #dynamiclib & executable & staticlib

# Assume that the user will provide their own linker rule here
ifdef MKDEBUG
$$(info Not generating a linker rule for $1/$2 because its BINTYPE is "$$($2_BINTYPE)")
endif #MKDEBUG

endif #dynamiclib & executable & staticlib


ifdef MKTRACE
$$(info Done generating target rules for $1+$2)
endif #MKTRACE

endef #_generate_target
generate_target = $(eval $(call _generate_target,$1,$2))
#####




#####
# docker_compose($1: project directory)
#
# Rules for deploying a docker-compose project
#####
define _docker_compose

$$(call add_phony_target,docker-build[$1])
docker-build[$1]: docker-build-one[$1]

$$(call add_phony_target,docker-build-one[$1])
docker-build-one[$1]: docker-rebuild-one[$1]

$$(call add_phony_target,docker-rebuild[$1])
docker-rebuild[$1]: docker-rebuild-one[$1]

$$(call add_phony_target,docker-rebuild-one[$1])
docker-rebuild-one[$1]:
	$$(_V)echo "Building images with docker-compose in $1"
	$$(_v)cd $1 && docker-compose build

$$(call add_phony_target,docker-start[$1])
docker-start[$1]: docker-start-one[$1]

$$(call add_phony_target,docker-start-one[$1])
docker-start-one[$1]:
	$$(_V)echo "Starting containers with docker-compose in $1"
	$$(_v)cd $1 && docker-compose up -d

$$(call add_phony_target,docker-restart[$1])
docker-restart[$1]: docker-restart-one[$1]

$$(call add_phony_target,docker-restart-one[$1])
docker-restart-one[$1]:
	$$(_V)echo "Restarting containers with docker-compose in $1"
	$$(_v)cd $1 && docker-compose restart

$$(call add_phony_target,docker-stop[$1])
docker-stop[$1]: docker-stop-one[$1]

$$(call add_phony_target,docker-stop-one[$1])
docker-stop-one[$1]:
	$$(_V)echo "Stopping containers with docker-compose in $1"
	$$(_v)cd $1 && docker-compose down

$$(call add_phony_target,docker-clean[$1])
docker-clean[$1]: docker-clean-one[$1]

$$(call add_phony_target,docker-clean-one[$1])
docker-clean-one[$1]:
	$$(_V)echo "Removing containers with docker-compose in $1"
	$$(_v)cd $1 && docker-compose rm --stop

endef #_docker_compose
docker_compose = $(eval $(call _docker_compose,$1))
#####




#####
# add_publish_rule($1: project directory, $2: path containing files to publish, $3: list of files under $2 to publish)
#
# Define a rule for copying a file to a project's publish directory
#####
define _add_publish_rule

ifdef MKDEBUG
$$(info add_publish_rule($1,$2,$3))
endif #MKDEBUG

$1+$2+PUB := $$(PUB_DIR)/$$(patsubst /%,%,$1)
$1+$2+DST := $$(addprefix $$($1+$2+PUB)/,$$(notdir $3))

publish-one[$1]: $$($1+$2+DST)

# Publishing rule
$$($1+$2+DST): $$($1+$2+PUB)/%: $2/%
	$$(_V)echo "Publishing $1/$$*"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

endef
add_publish_rule = $(eval $(call _add_publish_rule,$1,$2,$3))
#####




#####
# link_project_target($1: project directory, $2: base target name (build, clean, docker-start, etc))
#
# Define the various project-specific rules, including:
#  * <target>[$1]: <target>-one[$1]     (building this project tree should build the current directory)
#  * <target>[<parent>]: <target>[$1]   (building the parent project tree should also build this project tree)
#####
define _link_project_target

ifdef MKTRACE
$$(info Tracing link_project_target($1,$2)...)
endif #MKTRACE

$2[$1]-DEPS :=

# This parent link isn't defining the rule but rather just adding a dependency.
# Therefore, we don't call the add_phony_target function here.
ifdef $1/..
$2[$$($1/..)]-DEPS += $2[$1]
$2[$$($1/..)]: $2[$1]
endif #DIR/..

$$(call add_phony_target,$2[$1])
$$(call add_phony_target,$2-one[$1])
$2[$1]: $2-one[$1]

endef #_link_project_target
link_project_target = $(eval $(call _link_project_target,$1,$2))
#####




#####
# include_subdir($1: subdirectory)
#
# Check for a Build.mk file in the given directory. If one exists, include it and
# automatically generate all target dependencies and rules to build the products.
#####
define _include_subdir

# Prevent accidentally including a project file multiple times
ifndef $1+INCLUDE_GUARD
$1+INCLUDE_GUARD := 1

# Allow overriding the Build.mk path for a directory
ifndef $1+BUILD_MK
$1+BUILD_MK := $$(wildcard $1/Build.mk)
endif

ifdef $1+BUILD_MK

# Append project directory to the list of discovered projects
PROJECT_LIST += $1

# Exactly one of these must be defined by Build.mk
TARGET :=
TARGETS :=

# For advanced users that want to define custom build rules for a directory
PRODUCT :=
PRODUCTS :=
CLEAN :=

# Optional list of files to publish
PUBLISH :=
PUBLISH_BUILD :=
PUBLISH_TOP :=
PUBLISH_LIBC :=
PUBLISH_LD :=

# Deployment
DEPLOY_COMMAND :=
DEPLOY_DEPS :=

# Optional CTF flag management
FLAG_FILE := $$(or $$(wildcard $1/real_flag.txt),$$(wildcard $1/flag.txt))
FLAG_DST := flag.txt

# These can optionally be defined by Build.mk for Docker management
DOCKERFILE :=
DOCKER_IMAGE :=
DOCKER_IMAGE_TAG :=
DOCKER_IMAGE_CUSTOM :=
DOCKER_CONTAINER :=
DOCKER_CHALLENGE_NAME :=
DOCKER_CHALLENGE_PATH :=
DOCKER_CHALLENGE_ARGS :=
DOCKER_BUILD_ARGS :=
DOCKER_BUILD_DEPS :=
DOCKER_START_DEPS :=
DOCKER_PORTS :=
DOCKER_PORT_ARGS :=
DOCKER_RUN_ARGS :=
DOCKER_PWNABLESERVER_ARGS :=
DOCKER_RUNNABLE :=
DOCKER_BUILD_ONLY :=
DOCKER_CPULIMIT := $$(DEFAULT_DOCKER_CPULIMIT)
DOCKER_MEMLIMIT := $$(DEFAULT_DOCKER_MEMLIMIT)
DOCKER_TIMELIMIT := $$(DEFAULT_DOCKER_TIMELIMIT)
DOCKER_WRITEABLE :=
DOCKER_PASSWORD := $$(DEFAULT_DOCKER_PASSWORD)

# These can optionally be defined to set directory-specific variables
BITS := $$(DEFAULT_BITS)
CPPFLAGS := $$(DEFAULT_CPPFLAGS)
CFLAGS := $$(DEFAULT_CFLAGS)
CXXFLAGS := $$(DEFAULT_CXXFLAGS)
OFLAGS := $$(DEFAULT_OFLAGS)
ASFLAGS := $$(DEFAULT_ASFLAGS)
LDFLAGS := $$(DEFAULT_LDFLAGS)
NO_EXTRA_CPPFLAGS :=
NO_EXTRA_CFLAGS :=
NO_EXTRA_CXXFLAGS :=
NO_EXTRA_OFLAGS :=
NO_EXTRA_ASFLAGS :=
NO_EXTRA_LDFLAGS :=
NO_EXTRA_FLAGS :=
SRCS := $$(patsubst $1/%,%,$$(foreach ext,c cpp S,$$(wildcard $1/*.$$(ext))))
CC := $$(DEFAULT_CC)
CXX := $$(DEFAULT_CXX)
AS := $$(DEFAULT_AS)
LD := $$(DEFAULT_LD)
AR := $$(DEFAULT_AR)
BINTYPE :=
LIBS :=
LDLIBS :=
USE_LIBPWNABLEHARNESS :=
NO_UNBUFFERED_STDIO :=
NO_RPATH :=

# Ubuntu/glibc versions
UBUNTU_VERSION :=
GLIBC_VERSION :=

# Hardening flags
RELRO := $$(DEFAULT_RELRO)
CANARY := $$(DEFAULT_CANARY)
NX := $$(DEFAULT_NX)
PIE := $$(DEFAULT_PIE)
ASLR := $$(DEFAULT_ASLR)
STRIP := $$(DEFAULT_STRIP)
DEBUG := $$(DEFAULT_DEBUG)

# Set DIR+BUILD to the build directory for this project folder
ifeq "$1" "."
# For container builds, this is the workspace directory
$1+BUILD := $$(BUILD)
else
# For container builds: subdirectories of the workspace directory
# For normal builds: subdirectories of the PwnableHarness repo
$1+BUILD := $$(BUILD)/$1
endif

# Define DIR and BUILD_DIR for use by Build.mk files
DIR := $1
BUILD_DIR := $$($1+BUILD)

# First, include the subdirectory's makefile
ifdef MKDEBUG
$$(info Including $$($1+BUILD_MK))
endif
include $$($1+BUILD_MK)

# Look for new definition of TARGET/TARGETS
ifdef TARGET
# It's an error to define both TARGET and TARGETS
ifdef TARGETS
$$(error $$($1+BUILD_MK) defined both TARGET ($$(TARGET)) and TARGETS ($$(TARGETS))!)
endif
$1+TARGETS := $$(TARGET)
else ifdef TARGETS
$1+TARGETS := $$(TARGETS)
else
# Neither TARGET nor TARGETS are defined. This Build.mk file may still be useful for deployment
ifdef MKDEBUG
$$(warning $$($1+BUILD_MK) defines no targets.)
endif
$1+TARGETS :=
endif

# Path where the build target binary will be written
$1+PRODUCT := $$(PRODUCT)

# List of target files produced by Build.mk
$1+PRODUCTS := $$(PRODUCTS)
ifndef $1+PRODUCTS
ifdef $1+PRODUCT
ifneq "$$(words $$($1+TARGETS))" "1"
$$(error $$($1+BUILD_MK) defined multiple targets but also the PRODUCT variable)
endif #len(TARGETS) != 1
$1+PRODUCTS := $$($1+PRODUCT)
else #DIR+PRODUCT
$1+PRODUCTS := $$(addprefix $$($1+BUILD)/,$$($1+TARGETS))
endif #DIR+PRODUCT
endif #DIR+PRODUCTS

# Publishing
$1+PUBLISH := $$(PUBLISH)
$1+PUBLISH_BUILD := $$(PUBLISH_BUILD)
$1+PUBLISH_TOP := $$(PUBLISH_TOP)
$1+PUBLISH_LIBC := $$(PUBLISH_LIBC)
$1+PUBLISH_LD := $$(PUBLISH_LD)
$1+PUBLISH_PROJ_FILES := $$(addprefix $1/,$$($1+PUBLISH))
$1+PUBLISH_BUILD_FILES := $$(addprefix $$($1+BUILD)/,$$($1+PUBLISH_BUILD))
$1+PUBLISH_ALL_FILES := $$(sort $$($1+PUBLISH_PROJ_FILES) $$($1+PUBLISH_BUILD_FILES) $$(PUBLISH_TOP))
$1+CLEAN := $$(CLEAN)

# Deployment
$1+DEPLOY_COMMAND := $$(DEPLOY_COMMAND)
$1+DEPLOY_DEPS := $$(DEPLOY_DEPS)

# CTF flag management
$1+FLAG_FILE := $$(FLAG_FILE)
$1+FLAG_DST := $$(FLAG_DST)

# Docker variables
$1+DOCKERFILE := $$(DOCKERFILE)
$1+DOCKER_IMAGE := $$(DOCKER_IMAGE)
$1+DOCKER_IMAGE_TAG := $$(DOCKER_IMAGE_TAG)
$1+DOCKER_IMAGE_CUSTOM := $$(DOCKER_IMAGE_CUSTOM)
$1+DOCKER_CONTAINER := $$(DOCKER_CONTAINER)
$1+DOCKER_CHALLENGE_NAME := $$(DOCKER_CHALLENGE_NAME)
$1+DOCKER_CHALLENGE_PATH := $$(DOCKER_CHALLENGE_PATH)
$1+DOCKER_CHALLENGE_ARGS := $$(DOCKER_CHALLENGE_ARGS)
$1+DOCKER_BUILD_ARGS := $$(DOCKER_BUILD_ARGS)
$1+DOCKER_BUILD_DEPS := $$(DOCKER_BUILD_DEPS)
$1+DOCKER_START_DEPS := $$(DOCKER_START_DEPS)
$1+DOCKER_PORTS := $$(DOCKER_PORTS)
$1+DOCKER_PORT_ARGS := $$(DOCKER_PORT_ARGS)
$1+DOCKER_RUN_ARGS := $$(DOCKER_RUN_ARGS)
$1+DOCKER_PWNABLESERVER_ARGS := $$(DOCKER_PWNABLESERVER_ARGS)
$1+DOCKER_RUNNABLE := $$(DOCKER_RUNNABLE)
$1+DOCKER_BUILD_ONLY := $$(DOCKER_BUILD_ONLY)
$1+DOCKER_CPULIMIT := $$(DOCKER_CPULIMIT)
$1+DOCKER_MEMLIMIT := $$(DOCKER_MEMLIMIT)
$1+DOCKER_TIMELIMIT := $$(DOCKER_TIMELIMIT)
$1+DOCKER_WRITEABLE := $$(DOCKER_WRITEABLE)
$1+DOCKER_PASSWORD := $$(DOCKER_PASSWORD)
$1+DOCKER_COMPOSE := $$(wildcard $1/docker-compose.yml)

# Directory specific variables
$1+BITS := $$(BITS)
$1+CPPFLAGS := $$(CPPFLAGS)
$1+CFLAGS := $$(CFLAGS)
$1+CXXFLAGS := $$(CXXFLAGS)
$1+OFLAGS := $$(OFLAGS)
$1+ASFLAGS := $$(ASFLAGS)
$1+LDFLAGS := $$(LDFLAGS)
$1+NO_EXTRA_CPPFLAGS := $$(NO_EXTRA_CPPFLAGS)
$1+NO_EXTRA_CFLAGS := $$(NO_EXTRA_CFLAGS)
$1+NO_EXTRA_CXXFLAGS := $$(NO_EXTRA_CXXFLAGS)
$1+NO_EXTRA_OFLAGS := $$(NO_EXTRA_OFLAGS)
$1+NO_EXTRA_ASFLAGS := $$(NO_EXTRA_ASFLAGS)
$1+NO_EXTRA_LDFLAGS := $$(NO_EXTRA_LDFLAGS)
$1+NO_EXTRA_FLAGS := $$(NO_EXTRA_FLAGS)
$1+SRCS := $$(addprefix $1/,$$(SRCS))
$1+CC := $$(CC)
$1+CXX := $$(CXX)
$1+AS := $$(AS)
$1+LD := $$(LD)
$1+AR := $$(AR)
$1+BINTYPE := $$(BINTYPE)
$1+LIBS := $$(LIBS)
$1+LDLIBS := $$(LDLIBS)
$1+USE_LIBPWNABLEHARNESS := $$(USE_LIBPWNABLEHARNESS)
$1+NO_UNBUFFERED_STDIO := $$(NO_UNBUFFERED_STDIO)
$1+NO_RPATH := $$(NO_RPATH)

# Ubuntu/glibc versions
ifdef UBUNTU_VERSION

ifdef GLIBC_VERSION
ifneq "$$(GLIBC_VERSION)" "$$(UBUNTU_TO_GLIBC[$$(UBUNTU_VERSION)])"
$$(error UBUNTU_VERSION ($$(UBUNTU_VERSION)) uses glibc $$(UBUNTU_TO_GLIBC[$$(UBUNTU_VERSION)]), but GLIBC_VERSION is $$(GLIBC_VERSION))
endif #glibc/ubuntu version mismatch
endif #GLIBC_VERSION

$1+UBUNTU_VERSION := $$(UBUNTU_VERSION)

else ifdef GLIBC_VERSION

ifndef GLIBC_TO_UBUNTU[$$(GLIBC_VERSION)]
$$(error No known Ubuntu version has glibc version $$(GLIBC_VERSION))
endif

$1+UBUNTU_VERSION := $$(GLIBC_TO_UBUNTU[$$(GLIBC_VERSION)])

else #!defined(UBUNTU_VERSION) && !defined(GLIBC_VERSION)

$1+UBUNTU_VERSION := $$(DEFAULT_UBUNTU_VERSION)

endif #UBUNTU_VERSION

# Fully qualified base image to use for the challenge image
$1+DOCKER_FULL_BASE := $$(PWNABLEHARNESS_REPO):base-$$($1+UBUNTU_VERSION)-$$(BASE_VERSION)

# Directory specific hardening flags
$1+RELRO := $$(RELRO)
$1+CANARY := $$(CANARY)
$1+NX := $$(NX)
$1+PIE := $$(PIE)
$1+ASLR := $$(ASLR)
$1+STRIP := $$(STRIP)
$1+DEBUG := $$(DEBUG)

# Produce target specific variables and build rules
# $$(foreach target,$$($1+TARGETS),$$(info $$(call _generate_target,$1,$$(target))))
$$(foreach target,$$($1+TARGETS),$$(call generate_target,$1,$$(target)))


## Directory specific build rules

# Build rules
build-one[$1]: $$($1+PRODUCTS)

# Publish rules
ifdef $1+PUBLISH_ALL_FILES

# Generate all the real publish rules based on the source directory
$1+PUBLISH_DIRS := $$(sort $$(patsubst %/,%,$$(dir $$($1+PUBLISH_ALL_FILES))))
$$(foreach d,$$($1+PUBLISH_DIRS),$$(call add_publish_rule,$1,$$d,$$(filter $$d/%,$$($1+PUBLISH_ALL_FILES))))

endif #$1+PUBLISH_ALL_FILES

# Deploy rules
ifdef $1+DEPLOY_COMMAND

deploy-one[$1]: $$($1+DEPLOY_DEPS)
	$$(_V)echo "Deploying $1"
	$$(_v)cd $1 && $$($1+DEPLOY_COMMAND)

else #DIR+DEPLOY_COMMAND

deploy-one[$1]: publish-one[$1]

ifdef $1+DOCKER_RUNNABLE

deploy-one[$1]: docker-start-one[$1]

endif #DIR+DOCKER_RUNNABLE
endif #DIR+DEPLOY_COMMAND

# Clean rules
clean[$1]: clean-one[$1]

$1+TO_CLEAN := $$($1+PRODUCTS)
ifneq "$$($1+BUILD)" ".build"
$1+TO_CLEAN += $$($1+BUILD)
endif

# Mark custom clean rule as phony
ifdef $1+CLEAN
.PHONY: $$($1+CLEAN)
endif #DIR+CLEAN

clean-one[$1]: $$($1+CLEAN)
	$$(_V)echo "Removing build directory and products for $1"
	$$(_v)rm -rf $$($1+TO_CLEAN)

## Docker variables

ifdef $1+DOCKER_COMPOSE
$$(call docker_compose,$1)
endif #DOCKER_COMPOSE

# If DOCKER_IMAGE was defined by Build.mk, add docker rules.
ifdef $1+DOCKER_IMAGE

# Use the specified tag rather than "latest" (if set)
ifdef $1+DOCKER_IMAGE_TAG
$1+DOCKER_TAG_ARG := $$($1+DOCKER_IMAGE):$$($1+DOCKER_IMAGE_TAG)
else #DIR+DOCKER_IMAGE_TAG
$1+DOCKER_TAG_ARG := $$($1+DOCKER_IMAGE)
endif #DIR+DOCKER_IMAGE_TAG

# Check if there is a Dockerfile in this directory
ifndef $1+DOCKERFILE
$1+DOCKERFILE := $$(wildcard $1/Dockerfile)

# If $1+Dockerfile doesn't exist, we will use the default Dockerfile
ifndef $1+DOCKERFILE
$1+DOCKERFILE := $1/default.Dockerfile

# Add a rule to generate a default.Dockerfile in the project directory
# Ignore the "SecretsUsedInArgOrEnv" build check which is triggered by CHALLENGE_PASSWORD.
# This usage is safe since it's just intended for pre-competition testing. The image produced
# isn't intended to keep that password secret.
# https://docs.docker.com/build/checks/#skip-checks
$1/default.Dockerfile: $$($1+BUILD_MK) $$(ROOT_DIR)/Macros.mk $$(ROOT_DIR)/VERSION
	$$(_v)echo '# check=skip=SecretsUsedInArgOrEnv' > $$@ \
		&& echo 'FROM $$($1+DOCKER_FULL_BASE)' >> $$@

endif #exists DIR+Dockerfile
endif #DOCKERFILE

# Add the Dockerfile as a dependency for the docker-build target
$1+DOCKER_BUILD_DEPS += $$($1+DOCKERFILE)

# The Build.mk file is a dependency for the docker-build target
$1+DOCKER_BUILD_DEPS += $$($1+BUILD_MK) $$(ROOT_DIR)/Macros.mk

# Ensure that DIR+DOCKER_CHALLENGE_NAME has a value. Default to the
# first target in DIR+TARGETS, or if that's not defined, the name of the image
ifdef $1+DOCKER_CHALLENGE_NAME
$1+DOCKER_RUNNABLE := true
else
ifndef $1+THIS_IS_THE_CORE_PROJECT
$1+DOCKER_CHALLENGE_NAME := $$(or $$(firstword $$($1+TARGETS)),$$($1+DOCKER_IMAGE))
endif
endif

# Ensure that DIR+DOCKER_CHALLENGE_PATH has a value. Default to the path to the
# built challenge binary
ifndef $1+DOCKER_CHALLENGE_PATH
ifndef $1+THIS_IS_THE_CORE_PROJECT
$1+DOCKER_CHALLENGE_PATH := $$(firstword $$($1+PRODUCTS))
endif
endif
ifdef $1+DOCKER_CHALLENGE_PATH
$1+DOCKER_BUILD_DEPS += $$($1+DOCKER_CHALLENGE_PATH)
endif

# Ensure that DIR+DOCKER_CONTAINER has a value. Default to the Docker image name,
# or if that's not defined, the challenge name
ifdef $1+DOCKER_CONTAINER
$1+DOCKER_RUNNABLE := true
else
$1+DOCKER_CONTAINER := $$(or $$(notdir $$($1+DOCKER_IMAGE)),$$($1+DOCKER_CHALLENGE_NAME))
endif

# Use DOCKER_PORTS to produce arguments for binding host ports
ifdef $1+DOCKER_PORTS
$1+DOCKER_PORT_ARGS := $$(foreach port,$$($1+DOCKER_PORTS),-p $$(port):$$(port))
$1+DOCKER_RUNNABLE := true

ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS += --build-arg "PORT=$$(firstword $$($1+DOCKER_PORTS))"
endif #DOCKER_IMAGE_CUSTOM
endif #DOCKER_PORTS

# Pass DOCKER_TIMELIMIT through as a build arg
ifdef $1+DOCKER_TIMELIMIT
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS += --build-arg "TIMELIMIT=$$($1+DOCKER_TIMELIMIT)"
endif #DOCKER_IMAGE_CUSTOM
endif #DOCKER_TIMELIMIT

# Check if DOCKER_RUN_ARGS was defined
ifdef $1+DOCKER_RUN_ARGS
$1+DOCKER_RUNNABLE := true
endif

# Append args for the challenge binary to pwnableserver's args (after a "--" sentinel)
ifdef $1+DOCKER_CHALLENGE_ARGS
$1+DOCKER_PWNABLESERVER_ARGS += -- $$($1+DOCKER_CHALLENGE_ARGS)
endif

# Add flag if the Docker container's filesystem should be read-only
ifndef $1+DOCKER_WRITEABLE
ifeq "$$(filter --read-only,$$($1+DOCKER_RUN_ARGS))" ""
$1+DOCKER_RUN_ARGS += --read-only
endif #--read-only
endif #DOCKER_WRITEABLE

# Add Docker arguments for limiting CPU usage of the container
ifdef $1+DOCKER_CPULIMIT
# https://docs.docker.com/engine/containers/resource_constraints/#configure-the-default-cfs-scheduler
$1+DOCKER_RUN_ARGS += --cpus=$$($1+DOCKER_CPULIMIT)
endif #DOCKER_CPULIMIT

# Add Docker arguments for limiting memory usage of the container
ifdef $1+DOCKER_MEMLIMIT
# Need to set both --memory and --memory-swap to properly limit memory usage.
# Otherwise, the container gets access to N bytes of memory PLUS N bytes of swap, which is stupid.
# https://docs.docker.com/engine/containers/resource_constraints/#prevent-a-container-from-using-swap
$1+DOCKER_RUN_ARGS += --memory=$$($1+DOCKER_MEMLIMIT) --memory-swap=$$($1+DOCKER_MEMLIMIT)
endif #DOCKER_MEMLIMIT

# If there's a password, supply it as an argument to pwnableserver
ifdef $1+DOCKER_PASSWORD
$1+DOCKER_BUILD_ARGS += --build-arg "CHALLENGE_PASSWORD=$$($1+DOCKER_PASSWORD)"
endif #DOCKER_PASSWORD

# Check if DOCKER_PWNABLESERVER_ARGS was defined
ifdef $1+DOCKER_PWNABLESERVER_ARGS
$1+DOCKER_BUILD_ARGS += --build-arg "PWNABLESERVER_EXTRA_ARGS=$$($1+DOCKER_PWNABLESERVER_ARGS)"
endif

# Apply DOCKER_BUILD_ONLY to cancel out DOCKER_RUNNABLE
ifdef $1+DOCKER_BUILD_ONLY
$1+DOCKER_RUNNABLE :=
endif

# Append CHALLENGE_NAME, CHALLENGE_PATH, and DIR to the list of docker build arg
ifndef $1+THIS_IS_THE_CORE_PROJECT
ifndef $1+DOCKER_IMAGE_CUSTOM
$1+DOCKER_BUILD_ARGS += \
	--build-arg "CHALLENGE_NAME=$$($1+DOCKER_CHALLENGE_NAME)" \
	--build-arg "CHALLENGE_PATH=$$($1+DOCKER_CHALLENGE_PATH)"

endif #DOCKER_IMAGE_CUSTOM
endif #Not top-level (building PwnableHarness itself)

# The "workdir" is a Docker volume that is mounted over the current working
# directory for the challenge process (/ctf). It contains the contents of
# the project's "workdir" folder (if present), and the flag file is copied
# in (with correct ownership and permissions) as well.
$1+WORKDIR := $$(wildcard $1/workdir)
$1+MOUNT_WORKDIR :=
$1+WORKDIR_VOLUME := $$(subst /,.,$$($1+DOCKER_IMAGE))-workdir
$1+WORKDIR_DEPS :=
$1+WORKDIR_COPY_CMDS :=

# Handle copying the workdir folder contents to the Docker volume
ifdef $1+WORKDIR
$1+MOUNT_WORKDIR := true
$1+WORKDIR_DEPS += $$(wildcard $1/workdir/*)
$1+WORKDIR_COPY_CMDS += \
	&& $$(DOCKER) cp $$($1+WORKDIR)/. $$($1+WORKDIR_VOLUME)-temp:/data
endif

# Adding the flag file to the docker image
$1+HAS_FLAG :=
ifdef $1+FLAG_FILE
ifdef $1+FLAG_DST
ifdef MKDEBUG
$$(info Preparing flag for docker image $$($1+DOCKER_TAG_ARG) in $$($1+FLAG_DST))
endif #MKDEBUG

# Handle copying the flag file and setting its ownership and permissions in the Docker volume
$1+HAS_FLAG := true
$1+DOCKER_BUILD_ARGS += --build-arg "FLAG_DST=$$($1+FLAG_DST)"
$1+MOUNT_WORKDIR := true
$1+WORKDIR_DEPS += $$($1+FLAG_FILE)
$1+WORKDIR_COPY_CMDS += \
	&& $$(DOCKER) cp $$($1+FLAG_FILE) $$($1+WORKDIR_VOLUME)-temp:/data/$$($1+FLAG_DST) \
	&& $$(DOCKER) run --rm -v $$($1+WORKDIR_VOLUME):/data busybox \
		sh -c 'chown root:1337 /data/$$($1+FLAG_DST) && chmod 0640 /data/$$($1+FLAG_DST)'
endif #FLAG_DST
endif #FLAG_FILE

ifdef $1+MOUNT_WORKDIR
$1+DOCKER_RUN_ARGS += -v $$($1+WORKDIR_VOLUME):/ctf:ro
$1+DOCKER_START_DEPS += $$($1+BUILD)/.docker_workdir_volume_marker
endif

# Assume that DOCKER_BUILD_ARGS is already formatted as a list of "--build-arg name=value"
$1+DOCKER_BUILD_FLAGS := $$($1+DOCKER_BUILD_ARGS)

# Only support amd64 images (for now)
$1+DOCKER_PLATFORM := --platform=linux/amd64


## Docker build rules

ifdef MKTRACE
$$(info Adding docker-build rules for $1)
endif #MKTRACE

# This only rebuilds the docker image if any of its prerequisites have
# been changed since the last docker build
docker-build-one[$1]: $$($1+BUILD)/.docker_build_marker

# Create a marker file to track last docker build time
$$($1+BUILD)/.docker_build_marker: $$($1+PRODUCTS) $$($1+DOCKER_BUILD_DEPS) $$($1+BUILD)/.dir
	$$(_V)echo "Building docker image $$($1+DOCKER_TAG_ARG)"
	$$(_v)$$(DOCKER) build $$($1+DOCKER_PLATFORM) -t $$($1+DOCKER_TAG_ARG) $$($1+DOCKER_BUILD_FLAGS) -f $$($1+DOCKERFILE) . \
		&& touch $$@

# This rebuilds the docker image no matter what
docker-rebuild-one[$1]: | $$($1+PRODUCTS) $$($1+DOCKER_BUILD_DEPS) $$($1+BUILD)/.dir
	$$(_V)echo "Rebuilding docker image $$($1+DOCKER_TAG_ARG)"
	$$(_v)$$(DOCKER) build $$($1+DOCKER_PLATFORM) -t $$($1+DOCKER_TAG_ARG) $$($1+DOCKER_BUILD_FLAGS) -f $$($1+DOCKERFILE) . \
		&& touch $$($1+BUILD)/.docker_build_marker

# Force remove the container, volume, and image
docker-clean-one[$1]:
	$$(_V)echo "Cleaning docker image/container/volume for $$($1+DOCKER_TAG_ARG)"
ifdef $1+DOCKER_RUNNABLE
	$$(_v)$$(DOCKER) rm -f $$($1+DOCKER_CONTAINER) >/dev/null 2>&1 || true
endif
ifdef $1+MOUNT_WORKDIR
	$$(_v)$$(DOCKER) volume rm -f $$($1+WORKDIR_VOLUME) >/dev/null 2>&1 || true
endif
	$$(_v)$$(DOCKER) rmi -f $$($1+DOCKER_TAG_ARG) >/dev/null 2>&1 || true
	$$(_v)rm -f $$($1+BUILD)/.docker_build_marker $$($1+BUILD)/.docker_workdir_volume_marker || true

## Docker run rules

ifdef $1+DOCKER_RUNNABLE

ifdef MKTRACE
$$(info Adding docker runnable rules for $1)
endif #MKTRACE

# When starting a container, make sure the docker image is built
# and up to date
docker-start-one[$1]: docker-build[$1] $$($1+DOCKER_START_DEPS)
	$$(_V)echo "Starting docker container $$($1+DOCKER_CONTAINER) from image $$($1+DOCKER_TAG_ARG)"
	$$(_v)$$(DOCKER) rm -f $$($1+DOCKER_CONTAINER) >/dev/null 2>&1 || true
	$$(_v)$$(DOCKER) run $$($1+DOCKER_PLATFORM) -itd --restart=unless-stopped --name $$($1+DOCKER_CONTAINER) \
		$$($1+DOCKER_PORT_ARGS) $$($1+DOCKER_RUN_ARGS) $$($1+DOCKER_TAG_ARG)

# Rule for mounting the workdir
ifdef $1+MOUNT_WORKDIR

ifdef MKTRACE
$$(info Adding docker workdir mounting rule for $1)
endif #MKTRACE

$$($1+BUILD)/.docker_workdir_volume_marker: $$($1+WORKDIR_DEPS)
	$$(_V)echo "Preparing workdir volume for $1"
	$$(_v)$$(DOCKER) volume rm -f $$($1+WORKDIR_VOLUME) >/dev/null 2>&1 || true
	$$(_v)$$(DOCKER) container rm -f $$($1+WORKDIR_VOLUME)-temp >/dev/null 2>&1 || true
	$$(_v)$$(DOCKER) volume create $$($1+WORKDIR_VOLUME) \
		&& $$(DOCKER) container create --name $$($1+WORKDIR_VOLUME)-temp -v $$($1+WORKDIR_VOLUME):/data busybox \
		$$($1+WORKDIR_COPY_CMDS) \
		&& $$(DOCKER) rm $$($1+WORKDIR_VOLUME)-temp \
		&& touch $$@

endif #MOUNT_WORKDIR

# Restart a docker container
docker-restart-one[$1]:
	$$(_V)echo "Restarting docker container $$($1+DOCKER_CONTAINER)"
	$$(_v)$$(DOCKER) restart $$($1+DOCKER_CONTAINER)

# Stop the docker container
docker-stop-one[$1]:
	$$(_V)echo "Stopping docker container $$($1+DOCKER_CONTAINER)"
	$$(_v)$$(DOCKER) stop $$($1+DOCKER_CONTAINER) >/dev/null 2>&1 || true

endif #DOCKER_RUNNABLE

endif #DOCKER_IMAGE


# Decide whether to grab the 32-bit or 64-bit libc
ifeq "$$($1+BITS)" "32"
$1+LIBC_PATH := /lib/i386-linux-gnu/libc.so.6
$1+LDSO_PATH := /lib/ld-linux.so.2
else
$1+LIBC_PATH := /lib/x86_64-linux-gnu/libc.so.6
$1+LDSO_PATH := /lib64/ld-linux-x86-64.so.2
endif

# Publish libc for the challenge
ifdef $1+PUBLISH_LIBC

ifdef MKTRACE
$$(info Adding publish libc rules for $1)
endif #MKTRACE

publish-one[$1]: $$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC)

# Copy the libc from Docker only if the challenge builds a Docker image
ifdef $1+DOCKER_IMAGE
# If the challenge has a Docker image, copy the libc from there
$$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC): docker-build-one[$1]
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LIBC) from docker image $$($1+DOCKER_TAG_ARG):$$($1+LIBC_PATH)"
	$$(_v)mkdir -p $$(@D) && $$(DOCKER) run $$($1+DOCKER_PLATFORM) --rm --entrypoint /bin/cat $$($1+DOCKER_TAG_ARG) $$($1+LIBC_PATH) > $$@

else #DOCKER_IMAGE
# If the challenge doesn't run in Docker, copy the system's libc
$$(PUB_DIR)/$1/$$($1+PUBLISH_LIBC): $$($1+LIBC_PATH)
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LIBC) from $$<"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

endif #DOCKER_IMAGE
endif #PUBLISH_LIBC

# Publish ld.so for the challenge
ifdef $1+PUBLISH_LD

ifdef MKTRACE
$$(info Adding publish ld.so rules for $1)
endif #MKTRACE

publish-one[$1]: $$(PUB_DIR)/$1/$$($1+PUBLISH_LD)

# Copy the ld.so from Docker only if the challenge builds a Docker image
ifdef $1+DOCKER_IMAGE
# If the challenge has a Docker image, copy the ld.so from there
$$(PUB_DIR)/$1/$$($1+PUBLISH_LD): docker-build-one[$1]
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LD) from docker image $$($1+DOCKER_TAG_ARG):$$($1+LDSO_PATH)"
	$$(_v)mkdir -p $$(@D) && $$(DOCKER) run $$($1+DOCKER_PLATFORM) --rm --entrypoint /bin/cat $$($1+DOCKER_TAG_ARG) $$($1+LDSO_PATH) > $$@

else #DOCKER_IMAGE
# If the challenge doesn't run in Docker, copy the system's libc
$$(PUB_DIR)/$1/$$($1+PUBLISH_LD): $$($1+LDSO_PATH)
	$$(_V)echo "Publishing $1/$$($1+PUBLISH_LD) from $$<"
	$$(_v)mkdir -p $$(@D) && cat $$< > $$@

endif #DOCKER_IMAGE
endif #PUBLISH_LD

ifdef MKTRACE
$$(info Done processing $1's project file $$($1+BUILD_MK))
endif #MKTRACE

endif #BUILD_MK

# Link this directory's project targets
$$(foreach proj,$$(PROJECT_TARGETS),$$(call link_project_target,$1,$$(proj)))

endif #INCLUDE_GUARD
endef #_include_subdir
include_subdir = $(eval $(call _include_subdir,$1))
#####


#####
# recurse_subdir($1: subdirectory)
#
# Perform a depth-first recursion through the given directory including all Build.mk files found.
#####
define _recurse_subdir
ifeq "$$(wildcard $1)" ""
$$(warning Skipping "$1" as it doesn't exist, is there a file with spaces in the directory tree?)
else #exists($1)

# Add the ".." link if not in the workspace root
ifneq "$1" "."
$1/.. := $$(patsubst %/,%,$$(dir $1))
endif #not workspace root

# Include this directory's Build.mk file if it exists
$$(call include_subdir,$1)

# Ensure DIR+SUBDIRS has a value
ifndef $1+SUBDIRS
$1+SUBDIRS :=
endif

# Make a list of all items in this directory that are directories
$1+RAW_DIRLIST := $$(wildcard $1/*/)

# In case a directory had a space in its filename, filter that out with a pattern
$1+DIRLIST := $$(filter $1/%/,$$($1+RAW_DIRLIST))

# Check if any directories were skipped
$1+SKIPPED := $$(filter-out $1/%/,$$($1+RAW_DIRLIST))
ifdef $1+SKIPPED
$$(warning Skipping "$$($1+SKIPPED)" due to spaces in the path)
endif

# Strip the trailing "/" from directories, and join DIRLIST with SUBDIRS
$1+SUBDIRS := $$(patsubst %/,%,$$($1+SUBDIRS) $$(dir $$($1+DIRLIST)))

# Remove current directory and blacklisted items from the list of subdirectories
$1+SUBDIRS := $$(filter-out $1 %.disabled $$(addprefix %/,$$(RECURSION_BLACKLIST)),$$($1+SUBDIRS))

# Strip off the leading "./" in the subdirectory names
$1+SUBDIRS := $$(sort $$(patsubst ./%,%,$$($1+SUBDIRS)))

ifdef MKDEBUG
ifdef $1+SUBDIRS
$$(info Recursing from $1 into $$($1+SUBDIRS))
endif
endif

# Recurse into each subdirectory
$$(foreach sd,$$($1+SUBDIRS),$$(call recurse_subdir,$$(sd)))

# If there's an After.mk present, include it after the Build.mk for the project and all
# descendent projects have been included.
ifneq "$$(wildcard $1/After.mk)" ""

DIR := $1

ifdef MKDEBUG
$$(info Including $1/After.mk)
endif
include $1/After.mk

endif #DIR/After.mk
endif #exists($1)
endef #_recurse_subdir
recurse_subdir = $(eval $(call _recurse_subdir,$1))
#####
