TARGET := stack0

GCC := gcc -m32
CC := $(GCC)
LD := $(GCC)

CFLAGS := -O0 -fno-stack-protector
LDFLAGS := -Wl,-rpath,/usr/local/lib -Wl,-z,execstack
LDLIBS := -lpwnable_harness32

# Setting up source and build paths
BUILD := build
SRCS := $(wildcard *.c)
OBJS := $(addprefix $(BUILD)/,$(SRCS:=.o))
DEPS := $(OBJS:.o=.d)

DOCKER_IMAGE := c0deh4cker/$(TARGET)

# Print all commands executed when VERBOSE is defined
ifdef VERBOSE
_v :=
else
_v := @
endif


# Default rule
all: $(TARGET)

# Rule for building a docker image according to the Dockerfile
docker-build: $(TARGET)
	@echo "Building docker image"
	$(_v)docker build -t $(DOCKER_IMAGE) --build-arg RUNTIME_NAME=$(TARGET) .

# Rule for starting a docker container
docker-start: docker-build
	@echo "Starting docker container"
	$(_v)-docker rm -f $(TARGET)
	$(_v)docker run --name $(TARGET) -itd -v /etc/localtime:/etc/localtime:ro -p 32101:32101 $(DOCKER_IMAGE)

# Restart is an alias for start
docker-restart: docker-start

# Rule for stopping a running docker container
docker-stop:
	@echo "Stopping docker container"
	$(_v)docker stop $(TARGET)

# Compiler rule
$(BUILD)/%.o: % | $(BUILD)/.dir
	@echo "Compiling $<"
	$(_v)$(CC) $(CFLAGS) -MD -MP -MF $(BUILD)/$*.d -c -o $@ $<

# Linker rule
$(TARGET): $(OBJS)
	@echo "Linking $@"
	$(_v)$(LD) $(LDFLAGS) -o $@ $^ $(LDLIBS)

# Build dependency rules
-include $(DEPS)


clean:
	@echo "Removing built products"
	$(_v)rm -rf $(BUILD) $(TARGET)


# Make sure that the .dir files aren't automatically deleted after building
.SECONDARY:

%/.dir:
	$(_v)mkdir -p $* && touch $@

.PHONY: all docker-build docker-start docker-stop clean
