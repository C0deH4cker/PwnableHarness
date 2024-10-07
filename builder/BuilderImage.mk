# "But who builds the builders?"
#
# Docker image tag versioning strategy for builder images:
#
# * builder-<ubuntu tag>-v<pwnableharness version>
#     Specific base image and version of PwnableHarness
# * builder-v<pwnableharness version>
#     Alias of builder-18.04-v<pwnableharness version>
# * builder-<ubuntu tag>
#     Specific base image, latest version of PwnableHarness
# * builder-latest
#     Default base image (18.04 for now), latest version of PwnableHarness

# Files used when building the builder container
PWNABLE_BUILDER_DEPS := \
	$(addprefix $(PWNABLE_BUILDER_DIR)/,builder.Dockerfile builder-entrypoint.sh builder-sudo.sh pwnmake-in-container) \
	.dockerignore \
	Macros.mk \
	Makefile \
	$(addprefix $(PWNABLE_DIR)/, \
		base.Dockerfile \
		BaseImage.mk \
		Build.mk \
		get_supported_ubuntu_versions.py \
		pwnable_harness.c \
		pwnable_harness.h \
		pwnable_server.c \
		stdio_unbuffer.c \
		UbuntuVersions.mk \
	)

# The Ubuntu version used for PwnableHarness images with tags like
# "builder-v<pwnableharness version>" and "builder-latest".
# Keeping default below 19.10 for now because that's when 32-bit support was dropped.
# Keep aligned with the first line of builder.Dockerfile!
PWNABLE_BUILDER_DEFAULT_BASE := 18.04
PWNABLE_BUILDER_DEFAULT_ALIAS := $(UBUNTU_VERSION_TO_ALIAS[$(PWNABLE_BUILDER_DEFAULT_BASE)])
PWNABLE_BUILDER_DEFAULT_TAG := builder-$(PWNABLE_BUILDER_DEFAULT_BASE)-$(PWNABLEHARNESS_VERSION)


#
# Building
#
# docker-builder-build[<ubuntu-version>]
#  \- docker-builder-build[<ubuntu-version>]
#    \- PWNABLE_BUILD/.docker_builder_build_marker.<ubuntu version>
#         (tags builder-<ubuntu version>-v<pwnableharness version)
#
# docker-builder-build[<ubuntu-alias>]
#  \- docker-builder-tag[<ubuntu-alias>]
#

$(call generate_dependency_list,docker-builder-build,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_target,docker-builder-build)
docker-builder-build: docker-builder-build[$(PWNABLE_BUILDER_DEFAULT_BASE)]

# Targets like docker-builder-build[<ubuntu-version>] go through the rule below for .docker_builder_build_marker.%
$(patsubst %,docker-builder-build[%],$(UBUNTU_VERSIONS)): docker-builder-build[%]: $(PWNABLE_BUILD)/.docker_builder_build_marker.%

# This rule only needs to be re-run when one of PWNABLE_BUILDER_FILES is modified
$(PWNABLE_BUILD)/.docker_builder_build_marker.%: $(PWNABLE_BUILDER_DEPS)
	$(_V)echo "Building PwnableHarness builder image for ubuntu:$*"
	$(_v)$(DOCKER) build \
			-f $(PWNABLE_BUILDER_DIR)/builder.Dockerfile \
			--build-arg BASE_IMAGE=ubuntu:$* \
			$(if $(UBUNTU_32BIT_SUPPORT[$*]),,--build-arg CONFIG_IGNORE_32BIT=1) \
			--build-arg DIR=$(PWNABLE_BUILDER_DIR) \
			--build-arg GIT_HASH=$$(git rev-parse HEAD) \
			--build-arg VERSION=$(PWNABLEHARNESS_VERSION) \
			-t $(PWNABLEHARNESS_REPO):builder-$*-$(PWNABLEHARNESS_VERSION) . \
		&& mkdir -p $(@D) && touch $@

# Define phony targets like docker-builder-build[<ubuntu-alias>].
# These rules actually just depend on docker-builder-tag[<ubuntu-alias>],
# which will build the image for the corresponding Ubuntu version and then
# tag that image using the named Ubuntu alias.
define docker_builder_build_template

.PHONY: docker-builder-build[$1]
docker-builder-build[$1]: docker-builder-tag[$1]

endef #docker_builder_build_template
$(call generate_ubuntu_aliased_rules,docker_builder_build_template)
$(call add_target,docker-builder-build[<ubuntu-version>])


#
# Tagging
#
# docker-builder-tag
#  \- docker-builder-tag-version
#      \- docker-builder-tag-version[<ubuntu-version>]
#          \- docker-builder-build[<ubuntu-version>]
#             (builds builder-<ubuntu-version>-v<pwnableharness version>)
#      \- docker-builder-tag-version[<ubuntu-alias>]
#         (tags builder-<ubuntu-alias>-v<pwnableharness version>)
#  \- docker-builder-tag-default-version
#         (tags builder-v<pwnableharness version>)
#  \- docker-builder-tag-latest
#      \- docker-builder-tag-latest[<ubuntu-version>]
#         (tags builder-<ubuntu version>)
#      \- docker-builder-tag-latest[<ubuntu-alias>]
#         (tags builder-<ubuntu-alias>)
#  \- docker-builder-tag-default-latest
#         (tags builder-latest)
#

$(call generate_dependency_list,docker-builder-tag-version,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call generate_dependency_list,docker-builder-tag-latest,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_targets, \
	docker-builder-tag \
	docker-builder-tag-version \
	docker-builder-tag-default-version \
	docker-builder-tag-latest \
	docker-builder-tag-default-latest \
)

$(call add_targets, \
	docker-builder-tag-version[<ubuntu-version>] \
	docker-builder-tag-latest[<ubuntu-version>] \
)

docker-builder-tag: docker-builder-tag-version
docker-builder-tag: docker-builder-tag-default-version
docker-builder-tag: docker-builder-tag-latest
docker-builder-tag: docker-builder-tag-default-latest
docker-builder-tag-version: docker-builder-tag-version[$(PWNABLE_BUILDER_DEFAULT_BASE)]
docker-builder-tag-version: docker-builder-tag-version[$(PWNABLE_BUILDER_DEFAULT_ALIAS)]
docker-builder-tag-latest: docker-builder-tag-latest[$(PWNABLE_BUILDER_DEFAULT_BASE)]
docker-builder-tag-latest: docker-builder-tag-latest[$(PWNABLE_BUILDER_DEFAULT_ALIAS)]

# docker-builder-tag-version[<ubuntu-version>] is a nickname for docker-builder-build-version[<ubuntu-version>]
$(patsubst %,docker-builder-tag-version[%],$(UBUNTU_VERSIONS)): docker-builder-tag-version[%]: docker-builder-build[%]

# (tags builder-<ubuntu-alias>-v<pwnableharness version>)
define docker_builder_tag_version_aliased_template

.PHONY: docker-builder-tag-version[$1]
docker-builder-tag-version[$1]: docker-builder-build[$2]
	$$(_V)echo "Tagging Docker image with tag 'builder-$2-$$(PWNABLEHARNESS_VERSION)' as 'builder-$1-$$(PWNABLEHARNESS_VERSION)'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):builder-$2-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):builder-$1-$$(PWNABLEHARNESS_VERSION)

endef #docker_builder_tag_version_aliased_template
$(call generate_ubuntu_aliased_rules,docker_builder_tag_version_aliased_template)

# (tags builder-v<pwnableharness version>)
docker-builder-tag-default-version: docker-builder-build[$(PWNABLE_BUILDER_DEFAULT_BASE)]
	$(_V)echo "Tagging Docker image with tag '$(PWNABLE_BUILDER_DEFAULT_TAG)' as 'builder-$(PWNABLEHARNESS_VERSION)'"
	$(_v)$(DOCKER) tag \
		$(PWNABLEHARNESS_REPO):$(PWNABLE_BUILDER_DEFAULT_TAG) \
		$(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION)

# (tags builder-<ubuntu version>)
define docker_builder_tag_latest_both_template

.PHONY: docker-builder-tag-latest[$1]
docker-builder-tag-latest[$1]: docker-builder-tag-version[$1]
	$$(_V)echo "Tagging Docker image with tag 'builder-$1-$$(PWNABLEHARNESS_VERSION)' as 'builder-$1'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):builder-$1-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):builder-$1

endef #docker_builder_tag_latest_both_template
$(call generate_ubuntu_both_rules,docker_builder_tag_latest_both_template)

# (tags builder-latest)
docker-builder-tag-default-latest: docker-builder-build
	$(_V)echo "Tagging Docker image with tag '$(PWNABLE_BUILDER_DEFAULT_TAG)' as 'builder-latest'"
	$(_v)$(DOCKER) tag \
		$(PWNABLEHARNESS_REPO):$(PWNABLE_BUILDER_DEFAULT_TAG) \
		$(PWNABLEHARNESS_REPO):builder-latest


#
# Pushing
#
# docker-builder-push
#  \- docker-builder-push-version
#      \- docker-builder-push-version[<ubuntu version or alias>]
#          \- docker-builder-tag-version[<ubuntu version or alias>]
#         (pushes builder-<ubuntu version or alias>-v<pwnableharness version)
#  \- docker-builder-push-default-version
#      \- docker-builder-tag-default-version
#         (pushes builder-v<pwnableharness version>)
#  \- docker-builder-push-latest
#      \- docker-builder-push-latest[<ubuntu version or alias>]
#          \- docker-builder-tag-latest[<ubuntu version or alias>]
#         (pushes builder-<ubuntu version or alias>)
#  \- docker-builder-push-default-latest
#      \- docker-builder-tag-default-latest
#         (pushes builder-latest)
#

$(call generate_dependency_list,docker-builder-push-version,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call generate_dependency_list,docker-builder-push-latest,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_targets, \
	docker-builder-push \
	docker-builder-push-version \
	docker-builder-push-default-version \
	docker-builder-push-latest \
	docker-builder-push-default-latest \
)
$(call add_targets, \
	docker-builder-push[<ubuntu-version>] \
	docker-builder-push-latest[<ubuntu-version>] \
)

docker-builder-push: docker-builder-push-version
docker-builder-push: docker-builder-push-default-version
docker-builder-push: docker-builder-push-latest
docker-builder-push: docker-builder-push-default-latest
docker-builder-push-version: docker-builder-push-version[$(PWNABLE_BUILDER_DEFAULT_BASE)]
docker-builder-push-version: docker-builder-push-version[$(PWNABLE_BUILDER_DEFAULT_ALIAS)]
docker-builder-push-latest: docker-builder-push-latest[$(PWNABLE_BUILDER_DEFAULT_BASE)]
docker-builder-push-latest: docker-builder-push-latest[$(PWNABLE_BUILDER_DEFAULT_ALIAS)]

# (push builder-<ubuntu version or alias>-v<pwnableharness version)
docker-builder-push-version[%]: docker-builder-tag-version[%]
	$(_V)echo "Pushing tag 'builder-$*-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):builder-$*-$(PWNABLEHARNESS_VERSION)

# (push builder-v<pwnableharness version>)
docker-builder-push-default-version: docker-builder-tag-default-version
	$(_V)echo "Pushing tag 'builder-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION)

# (push builder-<ubuntu version or alias>)
docker-builder-push-latest[%]: docker-builder-tag-latest[%]
	$(_V)echo "Pushing tag 'builder-$*' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):builder-$*

# (push builder-latest)
docker-builder-push-default-latest: docker-builder-tag-default-latest
	$(_V)echo "Pushing tag 'builder-latest' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):builder-latest


#
# Cleaning
#
# docker-builder-clean
#  \- docker-builder-clean-version
#      \- docker-builder-clean-version[<ubuntu version or alias>]
#  \- docker-builder-clean-default-version
#  \- docker-builder-clean-latest
#      \- docker-builder-clean-latest[<ubuntu version or alias>]
#  \- docker-builder-clean-default-latest
#

$(call generate_dependency_list,docker-builder-clean,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_targets, \
	docker-builder-clean \
	docker-builder-clean-version \
	docker-builder-clean-default-version \
	docker-builder-clean-latest \
	docker-builder-clean-default-latest \
)
$(call add_targets, \
	docker-builder-clean-version[<ubuntu-version>] \
	docker-builder-clean-latest[<ubuntu-version>] \
)

docker-builder-clean: docker-builder-clean-version
docker-builder-clean: docker-builder-clean-default-version
docker-builder-clean: docker-builder-clean-latest
docker-builder-clean: docker-builder-clean-default-latest
docker-builder-clean-version: docker-builder-clean-version[$(PWNABLE_BUILDER_DEFAULT_BASE)]
docker-builder-clean-version: docker-builder-clean-version[$(PWNABLE_BUILDER_DEFAULT_ALIAS)]
docker-builder-clean-latest: docker-builder-clean-latest[$(PWNABLE_BUILDER_DEFAULT_BASE)]
docker-builder-clean-latest: docker-builder-clean-latest[$(PWNABLE_BUILDER_DEFAULT_ALIAS)]

# Remove builder-<ubuntu version>-v<pwnableharness version> tags and the build markers
$(patsubst %,docker-builder-clean-version[%],$(UBUNTU_VERSIONS)): docker-builder-clean-version[%]:
	$(_v)rm -f $(PWNABLE_BUILD)/.docker_builder_build_marker.$*
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):builder-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove builder-<ubuntu-alias>-v<pwnableharness version> tags
$(patsubst %,docker-builder-clean-version[%],$(UBUNTU_ALIASES)): docker-builder-clean-version[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):builder-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove builder-v<pwnableharness version> tag
docker-builder-clean-default-version:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):builder-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove builder-<ubuntu version or alias> tags
$(patsubst %,docker-builder-clean-latest[%],$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES)): docker-builder-clean-latest[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):builder-$* \
		>/dev/null 2>&1 || true

# Remove builder-latest tag
docker-builder-clean-default-latest:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):builder-latest \
		>/dev/null 2>&1 || true
