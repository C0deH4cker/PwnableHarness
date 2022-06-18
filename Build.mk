# This is not intended to be an example Build.mk file to reference.
# Please instead look at examples/stack0/Build.mk for reference.

PWNABLE_DIR := $(DIR)
PWNABLE_BUILD := $(BUILD_DIR)
LIB32 := libpwnableharness32.so
LIB64 := libpwnableharness64.so
PWNABLE_SERVER := pwnableserver
TARGETS := $(LIB64) $(PWNABLE_SERVER)

ifndef CONFIG_IGNORE_32BIT
TARGETS := $(TARGETS) $(LIB32)
endif #CONFIG_IGNORE_32BIT

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

DOCKER_IMAGE := $(PWNABLEHARNESS_REPO)
DOCKER_IMAGE_TAG := $(PWNABLEHARNESS_VERSION)
DOCKER_BUILD_ARGS := --build-arg "BUILD_DIR=$(BUILD_DIR)"

ifdef CONFIG_PUBLISH_LIBPWNABLEHARNESS
PUBLISH := $(LIB64)

ifndef CONFIG_IGNORE_32BIT
PUBLISH := $(PUBLISH) $(LIB32)
endif #CONFIG_IGNORE_32BIT
endif #CONFIG_PUBLISH_LIBPWNABLEHARNESS


ifndef CONTAINER_BUILD

# This should mirror the list of files added in builder.Dockerfile
PWNABLE_BUILDER_FILES := \
	.dockerignore \
	Build.mk \
	builder-entrypoint.sh \
	default.Dockerfile \
	Dockerfile \
	Macros.mk \
	Makefile \
	pwnable_harness.c \
	pwnable_harness.h \
	pwnable_server.c \
	stdio_unbuffer.c

PWNABLE_BUILDER_DEPS := $(addprefix $(PWNABLE_DIR)/,$(PWNABLE_BUILDER_FILES))

# "But who builds the builders?"
docker-builder-build: $(PWNABLE_BUILD)/.docker_builder_build_marker

# This rule only needs to be re-run when one of PWNABLE_BUILDER_FILES is modified
$(PWNABLE_BUILD)/.docker_builder_build_marker: $(PWNABLE_BUILDER_DEPS)
	$(_V)echo "Building PwnableHarness builder image"
	$(_v)docker build -f $(PWNABLE_DIR)/builder.Dockerfile -t $(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION) . \
		&& touch $@

docker-builder-push: docker-builder-build
	$(_V)echo "Pushing tag 'builder-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)docker push $(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION)

docker-builder-tag-latest: docker-builder-build
	$(_V)echo "Tagging Docker image with tag 'builder-$(PWNABLEHARNESS_VERSION)' as 'builder-latest'"
	$(_v)docker tag $(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION) $(PWNABLEHARNESS_REPO):builder-latest

docker-builder-push-latest: docker-builder-push docker-builder-tag-latest
	$(_V)echo "Pushing tag 'builder-latest' to $(PWNABLEHARNESS_REPO)"
	$(_v)docker push $(PWNABLEHARNESS_REPO):builder-latest

docker-builder-clean:
	$(_v)rm -f $(PWNABLE_BUILD)/.docker_builder_build_marker
	$(_v)docker rmi -f $(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION) $(PWNABLEHARNESS_REPO):builder-latest

docker-clean: docker-builder-clean

.PHONY: docker-builder-build docker-builder-push docker-builder-tag-latest docker-builder-push-latest docker-builder-clean

endif #CONTAINER_BUILD
