# Files used when building the pwnmake container
PWNMAKE_DEPS := \
	.dockerignore \
	get_supported_ubuntu_versions.py \
	Macros.mk \
	Makefile \
	stdio_unbuffer.c \
	UbuntuVersions.mk \
	VERSION \
	$(wildcard $(PWNABLEHARNESS_CORE_PROJECT)/*) \
	$(wildcard $(PWNCC_DIR)/*) \
	$(wildcard $(PWNMAKE_DIR)/*)

$(call add_phony_target,pwnmake-build)
pwnmake-build: $(BUILD)/.pwnmake_image_build_marker

$(BUILD)/.pwnmake_image_build_marker: $(PWNMAKE_DEPS)
	$(_V)echo "Building Docker image 'pwnmake-$(PWNABLEHARNESS_VERSION)'"
	$(_v)$(DOCKER) build \
			-f $(PWNMAKE_DIR)/pwnmake.Dockerfile \
			--build-arg DIR=$(PWNMAKE_DIR) \
			--build-arg GIT_HASH=$$(git rev-parse HEAD) \
			-t $(PWNABLEHARNESS_REPO):pwnmake-$(PWNABLEHARNESS_VERSION) . \
		&& mkdir -p $(@D) && touch $@

$(call add_phony_target,pwnmake-tag-latest)
pwnmake-tag-latest: pwnmake-build
	$(_V)echo "Tagging Docker image with tag 'pwnmake-$(PWNABLEHARNESS_VERSION)' as 'pwnmake-latest'"
	$(_v)$(DOCKER) tag \
			$(PWNABLEHARNESS_REPO):pwnmake-$(PWNABLEHARNESS_VERSION) \
			$(PWNABLEHARNESS_REPO):pwnmake-latest

$(call add_phony_target,pwnmake-push)
pwnmake-push: pwnmake-build
	$(_V)echo "Pushing Docker image with tag 'pwnmake-$(PWNABLEHARNESS_VERSION)'"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwnmake-$(PWNABLEHARNESS_VERSION)

$(call add_phony_target,pwnmake-push-latest)
pwnmake-push-latest: pwnmake-tag-latest
	$(_V)echo "Pushing Docker image with tag 'pwnmake-latest'"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwnmake-latest
