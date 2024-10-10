# Docker image tag versioning strategy for base images:
#
# * base-<ubuntu tag>-v<pwnableharness version>
#     Specific base image and version of PwnableHarness


#
# Building
#
# docker-base-build
#  \- docker-base-build[<ubuntu-version>]
#    \- CORE_BUILD/.docker_base_build_marker-<ubuntu-version>
#         (tags base-<ubuntu-version>-v<pwnableharness version)
#
# docker-base-build[<ubuntu-alias>]
#  \- docker-base-tag[<ubuntu-alias>]
#

$(call add_phony_target,docker-base-build)
$(call generate_dependency_list,docker-base-build,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

# Targets like docker-base-build[<ubuntu-version>] go through the rule below for .docker_base_build_marker-%
$(patsubst %,docker-base-build[%],$(UBUNTU_VERSIONS)): docker-base-build[%]: $(CORE_BUILD)/.docker_base_build_marker-%

define docker_base_build_template
PWNABLE_CORE_DEPS-$1 := $$(addprefix $$(CORE_BUILD)/,$$(CORE_TARGETS-$1))

$$(CORE_BUILD)/.docker_base_build_marker-$1: $$(PWNABLE_CORE_DEPS-$1)
	$$(_V)echo "Building PwnableHarness base image for ubuntu:$1"
	$$(_v)$$(DOCKER) build -f $$(CORE_DIR)/base.Dockerfile \
			--build-arg BASE_TAG=$1 \
			--build-arg BUILD_DIR=$$(CORE_BUILD) \
			-t $$(PWNABLEHARNESS_REPO):base-$1-$$(PWNABLEHARNESS_VERSION) . \
		&& mkdir -p $$(@D) && touch $$@

endef
$(call generate_ubuntu_versioned_rules,docker_base_build_template)

# Define phony targets like docker-base-build[<ubuntu-alias>].
# These rules actually just depend on docker-base-tag[<ubuntu-alias>],
# which will build the image for the corresponding Ubuntu version and then
# tag that image using the named Ubuntu alias.
define docker_base_build_alias_template

.PHONY: docker-base-build[$1]
docker-base-build[$1]: docker-base-tag[$1]

endef #docker_base_build_alias_template
$(call generate_ubuntu_aliased_rules,docker_base_build_alias_template)
$(call add_target,docker-base-build[<ubuntu-version>])

#
# Tagging
#
# docker-base-tag
#  \- docker-base-tag[<ubuntu-version>]
#      \- docker-base-build[<ubuntu-version>]
#  \- docker-base-tag[<ubuntu-alias>]
#     (tags base-<ubuntu-alias>-v<pwnableharness version>)
#

$(call add_phony_target,docker-base-tag)
$(call generate_dependency_list,docker-base-tag,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

# docker-base-tag[<ubuntu-version>] is a nickname for docker-base-build[<ubuntu-version>]
$(patsubst %,docker-base-tag[%],$(UBUNTU_VERSIONS)): docker-base-tag[%]: docker-base-build[%]

# (tags base-<ubuntu-alias>-v<pwnableharness version>)
define docker_base_tag_aliased_template

.PHONY: docker-base-tag[$1]
docker-base-tag[$1]: docker-base-build[$2]
	$$(_V)echo "Tagging Docker image with tag 'base-$2-$$(PWNABLEHARNESS_VERSION)' as 'base-$1-$$(PWNABLEHARNESS_VERSION)'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):base-$2-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):base-$1-$$(PWNABLEHARNESS_VERSION)

endef #docker_base_tag_aliased_template
$(call generate_ubuntu_aliased_rules,docker_base_tag_aliased_template)
$(call add_target,docker-base-tag[<ubuntu-version>])


#
# Pushing
#
# docker-base-push
#  \- docker-base-push[<ubuntu version or alias>]
#      \- docker-base-tag[<ubuntu version or alias>]
#     (pushes base-<ubuntu version or alias>-v<pwnableharness version)
#


$(call add_phony_target,docker-base-push)
$(call generate_dependency_list,docker-base-push,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call add_target,docker-base-push[<ubuntu-version>])

# (push base-<ubuntu version or alias>-v<pwnableharness version)
docker-base-push[%]: docker-base-tag[%]
	$(_V)echo "Pushing tag 'docker-base-$*-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):base-$*-$(PWNABLEHARNESS_VERSION)


#
# Cleaning
#
# docker-base-clean
#  \- docker-base-clean[<ubuntu-version>]
#  \- docker-base-clean[<ubuntu-alias>]
#
# docker-clean
#  \- docker-base-clean
#

$(call generate_dependency_list,docker-base-clean,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

# Remove all tags and build markers
$(call add_phony_target,docker-base-clean)

# Remove base-<ubuntu version>-v<pwnableharness version> tags and the build markers
$(call add_target,docker-base-clean[<ubuntu-version>])
$(patsubst %,docker-base-clean[%],$(UBUNTU_VERSIONS)): docker-base-clean[%]:
	-$(_v)rm -f $(CORE_BUILD)/.docker_base_build_marker.$*
	-$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):base-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1

# Remove base-<ubuntu-alias>-v<pwnableharness version> tags
$(patsubst %,docker-base-clean[%],$(UBUNTU_ALIASES)): docker-base-clean[%]:
	-$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):base-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1
