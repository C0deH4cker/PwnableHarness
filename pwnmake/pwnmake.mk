# Attempt to prevent accidentally updating a published version
ifeq "$(PHMAKE_VERSION)" "$(PHMAKE_RELEASED)"

.PHONY: pwnmake-build
pwnmake-build:
	@echo "Not building pwnmake, as version $(PHMAKE_VERSION) is already released!"
	$(_v)false

.PHONY: pwnmake-push
pwnmake-push:
	@echo "Not pushing pwnmake, as version $(PHMAKE_VERSION) is already released!"
	$(_v)false

.PHONY: pwnmake-push-latest
pwnmake-push-latest: pwnmake-push

else #PHMAKE_VERSION != PHMAKE_RELEASED

# Files used when building the pwnmake container
PWNMAKE_DEPS := \
	.dockerignore \
	$(BUILD)/cached_ubuntu_versions.mk \
	$(BUILD)/cached_glibc_versions.mk \
	Macros.mk \
	Makefile \
	stdio_unbuffer.c \
	UbuntuVersions.mk \
	Versions.mk \
	$(wildcard $(PWNCC_DIR)/*) \
	$(wildcard $(PWNMAKE_DIR)/*)

$(call add_phony_target,pwnmake-build)
pwnmake-build: $(BUILD)/.pwnmake_image_build_marker

$(BUILD)/.pwnmake_image_build_marker: $(PWNMAKE_DEPS)
	$(_V)echo "Building Docker image 'pwnmake-$(PHMAKE_VERSION)'"
	$(_v)$(DOCKER) build \
			-f $(PWNMAKE_DIR)/pwnmake.Dockerfile \
			--build-arg DIR=$(PWNMAKE_DIR) \
			--build-arg BUILD_DIR=$(BUILD) \
			--build-arg GIT_HASH=$$(git rev-parse HEAD) \
			-t $(PWNABLEHARNESS_REPO):pwnmake-$(PHMAKE_VERSION) . \
		&& mkdir -p $(@D) && touch $@

pwnmake-tag[$(PHMAKE_VERSION)]: pwnmake-build

$(call add_phony_target,pwnmake-tag[version])
pwnmake-tag[%]: pwnmake-build
	$(_V)echo "Tagging Docker image with tag 'pwnmake-$(PHMAKE_VERSION)' as 'pwnmake-$*'"
	$(_v)$(DOCKER) tag \
			$(PWNABLEHARNESS_REPO):pwnmake-$(PHMAKE_VERSION) \
			$(PWNABLEHARNESS_REPO):pwnmake-$*

$(call add_phony_target,pwnmake-push)
pwnmake-push: pwnmake-push[$(PHMAKE_VERSION)]
pwnmake-push: pwnmake-push[dev]

$(call add_phony_target,pwnmake-push-latest)
pwnmake-push-latest: pwnmake-push
pwnmake-push-latest: pwnmake-push[latest]

$(call add_phony_target,pwnmake-push[version])
pwnmake-push[%]: pwnmake-tag[%]
	$(_V)echo "Pushing Docker image with tag 'pwnmake-$*'"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwnmake-$*

endif #PHMAKE_VERSION != PHMAKE_RELEASED
