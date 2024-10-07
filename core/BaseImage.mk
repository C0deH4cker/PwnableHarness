# Docker image tag versioning strategy for base images:
#
# * <ubuntu tag>-v<pwnableharness version>
#     Specific base image and version of PwnableHarness
# * v<pwnableharness version>
#     Alias of 18.04-v<pwnableharness version>
# * <ubuntu tag>
#     Specific base image, latest version of PwnableHarness
# * latest
#     Default base image (18.04 for now), latest version of PwnableHarness

# Files that are directly copied into the base image (excluding ONBUILD rules)
PWNABLE_CORE_DEPS := $(addprefix $(PWNABLE_BUILD)/,$(PWNABLE_TARGETS))

PWNABLEHARNESS_DEFAULT_BASE := $(DEFAULT_UBUNTU_VERSION)
PWNABLEHARNESS_DEFAULT_TAG := $(PWNABLEHARNESS_DEFAULT_BASE)-$(PWNABLEHARNESS_VERSION)


#
# Building
#
# docker-base-build
#  \- docker-base-build[<ubuntu-version>]
#    \- PWNABLE_BUILD/.docker_base_build_marker.<ubuntu-version>
#         (tags <ubuntu-version>-v<pwnableharness version)
#
# docker-base-build[<ubuntu-alias>]
#  \- docker-base-tag[<ubuntu-alias>]
#

$(call generate_dependency_list,docker-base-build,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_target,docker-base-build)
docker-base-build: docker-base-build[$(PWNABLEHARNESS_DEFAULT_BASE)]

# Targets like docker-base-build[<ubuntu-version>] go through the rule below for .docker_base_build_marker.%
$(patsubst %,docker-base-build[%],$(UBUNTU_VERSIONS)): docker-base-build[%]: $(PWNABLE_BUILD)/.docker_base_build_marker.%

# This rule only needs to be re-run when one of PWNABLE_CORE_FILES is modified
$(PWNABLE_BUILD)/.docker_base_build_marker.%: $(PWNABLE_CORE_DEPS)
	$(_V)echo "Building PwnableHarness base image for ubuntu:$*"
	$(_v)$(DOCKER) build -f $(PWNABLE_DIR)/base.Dockerfile \
			--build-arg BASE_IMAGE=ubuntu:$* \
			--build-arg BUILD_DIR=$(PWNABLE_BUILD) \
			-t $(PWNABLEHARNESS_REPO):$*-$(PWNABLEHARNESS_VERSION) . \
		&& mkdir -p $(@D) && touch $@

# Define phony targets like docker-base-build[<ubuntu-alias>].
# These rules actually just depend on docker-base-tag[<ubuntu-alias>],
# which will build the image for the corresponding Ubuntu version and then
# tag that image using the named Ubuntu alias.
define docker_base_build_template

.PHONY: docker-base-build[$1]
docker-base-build[$1]: docker-base-tag[$1]

endef #docker_base_build_template
$(call generate_ubuntu_aliased_rules,docker_base_build_template)
$(call add_target,docker-base-build[<ubuntu-version>])

#
# Tagging
#
# docker-base-tag
#  \- docker-base-tag-version
#      \- docker-base-tag-version[<ubuntu-version>]
#          \- docker-base-build[<ubuntu-version>]
#      \- docker-base-tag-version[<ubuntu-alias>]
#         (tags <ubuntu-alias>-v<pwnableharness version>)
#      \- docker-base-tag-default-version
#         (tags v<pwnableharness version>)
#  \- docker-base-tag-latest[<ubuntu-version>]
#         (tags <ubuntu-version>)
#  \- docker-base-tag-latest[<ubuntu-alias>]
#         (tags <ubuntu-alias>)
#  \- docker-base-tag-default-latest
#         (tags latest)
#

$(call generate_dependency_list,docker-base-tag-version,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call generate_dependency_list,docker-base-tag-latest,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_target,docker-base-tag)
docker-base-tag: docker-base-tag-latest

$(call add_phony_target,docker-base-tag-latest)
docker-base-tag-latest: docker-base-tag-version docker-base-tag-default-latest

# docker-base-tag-version[<ubuntu-version>] is a nickname for docker-base-build[<ubuntu-version>]
$(patsubst %,docker-base-tag-version[%],$(UBUNTU_VERSIONS)): docker-base-tag-version[%]: docker-base-build[%]

# (tags <ubuntu-alias>-v<pwnableharness version>)
define docker_base_tag_version_aliased_template

.PHONY: docker-base-tag-version[$1]
docker-base-tag-version[$1]: docker-base-build[$2]
	$$(_V)echo "Tagging Docker image with tag '$2-$$(PWNABLEHARNESS_VERSION)' as '$1-$$(PWNABLEHARNESS_VERSION)'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):$2-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):$1-$$(PWNABLEHARNESS_VERSION)

endef #docker_base_tag_version_aliased_template
$(call generate_ubuntu_aliased_rules,docker_base_tag_version_aliased_template)
$(call add_target,docker-base-tag-version[<ubuntu-version>])

# (tags v<pwnableharness version>)
$(call add_phony_target,docker-base-tag-default-version)
docker-base-tag-default-version: docker-base-build[$(PWNABLEHARNESS_DEFAULT_BASE)]
	$(_V)echo "Tagging Docker image with tag '$(PWNABLEHARNESS_DEFAULT_BASE)' as '$(PWNABLEHARNESS_VERSION)'"
	$(_v)$(DOCKER) tag \
		$(PWNABLEHARNESS_REPO):$(PWNABLEHARNESS_DEFAULT_BASE) \
		$(PWNABLEHARNESS_REPO):$(PWNABLEHARNESS_VERSION)

# (tags <ubuntu-version>)
define docker_base_tag_latest_versioned_template

.PHONY: docker-base-tag-latest[$1]
docker-base-tag-latest[$1]: docker-base-build[$1]
	$$(_V)echo "Tagging Docker image with tag '$1-$$(PWNABLEHARNESS_VERSION)' as '$1'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):$1-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):$1

endef #docker_base_tag_latest_versioned_template
$(call generate_ubuntu_versioned_rules,docker_base_tag_latest_versioned_template)
$(call add_target,docker-base-tag-latest[<ubuntu-version>])

# (tags <ubuntu-alias>)
define docker_base_tag_latest_aliased_template

.PHONY: docker-base-tag-latest[$1]
docker-base-tag-latest[$1]: docker-base-tag-alias[$1]
	$$(_V)echo "Tagging Docker image with tag '$1-$$(PWNABLEHARNESS_VERSION)' as '$1'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):$1-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):$1

endef #docker_base_tag_latest_aliased_template
$(call generate_ubuntu_aliased_rules,docker_base_tag_latest_aliased_template)
$(call add_target,docker-base-tag-latest[<ubuntu-version>])

# (tags latest)
$(call add_phony_target,docker-base-tag-default-latest)
docker-base-tag-default-latest:
	$(_V)echo "Tagging Docker image with tag '$(PWNABLEHARNESS_DEFAULT_BASE)' as 'latest'"
	$(_v)$(DOCKER) tag \
		$(PWNABLEHARNESS_REPO):$(PWNABLEHARNESS_DEFAULT_BASE) \
		$(PWNABLEHARNESS_REPO):latest


#
# Cleaning
#
# docker-base-clean-latest
#  \- docker-base-clean
#      \- docker-base-clean[<ubuntu-version>]
#      \- docker-base-clean[<ubuntu-alias>]
#  \- docker-base-clean-latest[<ubuntu version or alias>]
#
# docker-clean
#  \- docker-base-clean-latest
#

$(call generate_dependency_list,docker-base-clean,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

# Remove all tags and build markers
$(call add_phony_target,docker-base-clean)

# Remove <ubuntu version>-v<pwnableharness version> tags and the build markers
$(call add_target,docker-base-clean[<ubuntu-version>])
$(patsubst %,docker-base-clean[%],$(UBUNTU_VERSIONS)): docker-base-clean[%]:
	$(_v)rm -f $(PWNABLE_BUILD)/.docker_base_build_marker.$*
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove <ubuntu-alias>-v<pwnableharness version> tags
$(patsubst %,docker-base-clean[%],$(UBUNTU_ALIASES)): docker-base-clean[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove v<pwnableharness version> tag
$(call add_phony_target,docker-base-clean-version)
docker-base-clean-version:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove latest tag
$(call add_phony_target,docker-base-clean-latest)
docker-base-clean-latest: docker-base-clean
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):latest \
		>/dev/null 2>&1 || true

# Remove <ubuntu version or alias> tags
$(call add_target,docker-base-clean-latest[<ubuntu-version>])
$(patsubst %,docker-base-clean-latest[%],$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES)): docker-base-clean-latest[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):$* \
		>/dev/null 2>&1 || true


# TODO: docker-base-image[<ubuntu-version>] should pull instead of build
$(call add_target,docker-base-image[<ubuntu-version>])
$(patsubst %,docker-base-image[%],$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES)): docker-base-image[%]: docker-base-tag-version[%]
