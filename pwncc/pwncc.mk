# "But who builds the builders?"
#
# This file manages the "pwncc images" used by PwnableHarness. These pwncc
# images are based on pwncc.Dockerfile, and they are tiny images that are
# effectively just some Ubuntu image with GCC and Clang sprinkled on top.
# PwnableHarness will invoke these pwncc images for each compiler and linker
# command that it runs when building challenges (and the PwnableHarness core).
#
# Docker image tag versioning strategy for pwncc images:
#
# * pwncc-<ubuntu tag>-v<pwnableharness version>
#     Specific base image and version of PwnableHarness
# * pwncc-v<pwnableharness version>
#     Alias of pwncc-24.04-v<pwnableharness version>
# * pwncc-<ubuntu tag>
#     Specific base image, latest version of PwnableHarness
# * pwncc-latest
#     Default base image (24.04 for now), latest version of PwnableHarness

ifdef CONFIG_I_AM_C0DEH4CKER_HEAR_ME_ROAR

CONFIG_USE_PWNCC := 1

# The Ubuntu version used for PwnableHarness images with tags like
# "pwncc-v<pwnableharness version>" and "pwncc-latest".
PWNCC_DEFAULT_BASE := $(DEFAULT_UBUNTU_VERSION)
PWNCC_DEFAULT_ALIAS := $(UBUNTU_VERSION_TO_ALIAS[$(PWNCC_DEFAULT_BASE)])
PWNCC_DEFAULT_TAG := pwncc-$(PWNCC_DEFAULT_BASE)-$(PWNABLEHARNESS_VERSION)

#
# Building
#
# pwncc-build[<ubuntu-version>]
#    \- BUILD/.pwncc_build_marker-<ubuntu version>
#         (tags pwncc-<ubuntu version>-v<pwnableharness version)
#
# pwncc-build[<ubuntu-alias>]
#  \- pwncc-tag[<ubuntu-alias>]
#

$(call generate_dependency_list,pwncc-build,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_target,pwncc-build)
pwncc-build: pwncc-build[$(PWNCC_DEFAULT_BASE)]

# Targets like pwncc-build[<ubuntu-version>] go through the rule below for .pwncc_build_marker-%
$(patsubst %,pwncc-build[%],$(UBUNTU_VERSIONS)): pwncc-build[%]: $(BUILD)/.pwncc_build_marker-%

define pwncc_build_template
$$(BUILD)/.pwncc_build_marker-$1: $$(PWNCC_DIR)/pwncc.Dockerfile | $$(ROOT_DIR)/stdio_unbuffer.c
	$$(_V)echo "Building pwncc image for ubuntu:$1"
	$$(_v)$$(DOCKER) build \
			-f $$< \
			--build-arg BASE_IMAGE=ubuntu:$1 \
			$$(if $$(UBUNTU_32BIT_SUPPORT[$1]),,--build-arg CONFIG_IGNORE_32BIT=1) \
			-t $$(PWNABLEHARNESS_REPO):pwncc-$1-$$(PWNABLEHARNESS_VERSION) . \
		&& mkdir -p $$(@D) && touch $$@

endef #pwncc_build_template
$(call generate_ubuntu_versioned_rules,pwncc_build_template)

# Define phony targets like pwncc-build[<ubuntu-alias>].
# These rules actually just depend on pwncc-tag[<ubuntu-alias>],
# which will build the image for the corresponding Ubuntu version and then
# tag that image using the named Ubuntu alias.
define pwncc_build_alias_template

.PHONY: pwncc-build[$1]
pwncc-build[$1]: pwncc-tag-version[$1]

endef #pwncc_build_alias_template
$(call generate_ubuntu_aliased_rules,pwncc_build_alias_template)
$(call add_target,pwncc-build[<ubuntu-version>])


#
# Tagging
#
# pwncc-tag
#  \- pwncc-tag-version
#      \- pwncc-tag-version[<ubuntu-version>]
#          \- pwncc-build[<ubuntu-version>]
#             (builds pwncc-<ubuntu-version>-v<pwnableharness version>)
#      \- pwncc-tag-version[<ubuntu-alias>]
#         (tags pwncc-<ubuntu-alias>-v<pwnableharness version>)
#  \- pwncc-tag-default-version
#         (tags pwncc-v<pwnableharness version>)
#  \- pwncc-tag-latest
#      \- pwncc-tag-latest[<ubuntu-version>]
#         (tags pwncc-<ubuntu version>)
#      \- pwncc-tag-latest[<ubuntu-alias>]
#         (tags pwncc-<ubuntu-alias>)
#  \- pwncc-tag-default-latest
#         (tags pwncc-latest)
#

$(call generate_dependency_list,pwncc-tag-version,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call generate_dependency_list,pwncc-tag-latest,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_targets, \
	pwncc-tag \
	pwncc-tag-version \
	pwncc-tag-default-version \
	pwncc-tag-latest \
	pwncc-tag-default-latest \
)

$(call add_targets, \
	pwncc-tag-version[<ubuntu-version>] \
	pwncc-tag-latest[<ubuntu-version>] \
)

pwncc-tag: pwncc-tag-version
pwncc-tag: pwncc-tag-default-version
pwncc-tag: pwncc-tag-latest
pwncc-tag: pwncc-tag-default-latest
pwncc-tag-version: pwncc-tag-version[$(PWNCC_DEFAULT_BASE)]
pwncc-tag-version: pwncc-tag-version[$(PWNCC_DEFAULT_ALIAS)]
pwncc-tag-latest: pwncc-tag-latest[$(PWNCC_DEFAULT_BASE)]
pwncc-tag-latest: pwncc-tag-latest[$(PWNCC_DEFAULT_ALIAS)]

# pwncc-tag-version[<ubuntu-version>] is a nickname for pwncc-build-version[<ubuntu-version>]
$(patsubst %,pwncc-tag-version[%],$(UBUNTU_VERSIONS)): pwncc-tag-version[%]: pwncc-build[%]

# (tags pwncc-<ubuntu-alias>-v<pwnableharness version>)
define pwncc_tag_version_aliased_template

.PHONY: pwncc-tag-version[$1]
pwncc-tag-version[$1]: pwncc-build[$2]
	$$(_V)echo "Tagging Docker image with tag 'pwncc-$2-$$(PWNABLEHARNESS_VERSION)' as 'pwncc-$1-$$(PWNABLEHARNESS_VERSION)'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):pwncc-$2-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):pwncc-$1-$$(PWNABLEHARNESS_VERSION)

endef #pwncc_tag_version_aliased_template
$(call generate_ubuntu_aliased_rules,pwncc_tag_version_aliased_template)

# (tags pwncc-v<pwnableharness version>)
pwncc-tag-default-version: pwncc-build[$(PWNCC_DEFAULT_BASE)]
	$(_V)echo "Tagging Docker image with tag '$(PWNCC_DEFAULT_TAG)' as 'pwncc-$(PWNABLEHARNESS_VERSION)'"
	$(_v)$(DOCKER) tag \
		$(PWNABLEHARNESS_REPO):$(PWNCC_DEFAULT_TAG) \
		$(PWNABLEHARNESS_REPO):pwncc-$(PWNABLEHARNESS_VERSION)

# (tags pwncc-<ubuntu version>)
define pwncc_tag_latest_both_template

.PHONY: pwncc-tag-latest[$1]
pwncc-tag-latest[$1]: pwncc-tag-version[$1]
	$$(_V)echo "Tagging Docker image with tag 'pwncc-$1-$$(PWNABLEHARNESS_VERSION)' as 'pwncc-$1'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):pwncc-$1-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):pwncc-$1

endef #pwncc_tag_latest_both_template
$(call generate_ubuntu_both_rules,pwncc_tag_latest_both_template)

# (tags pwncc-latest)
pwncc-tag-default-latest: pwncc-build
	$(_V)echo "Tagging Docker image with tag '$(PWNCC_DEFAULT_TAG)' as 'pwncc-latest'"
	$(_v)$(DOCKER) tag \
		$(PWNABLEHARNESS_REPO):$(PWNCC_DEFAULT_TAG) \
		$(PWNABLEHARNESS_REPO):pwncc-latest


#
# Pushing
#
# pwncc-push
#  \- pwncc-push-version
#      \- pwncc-push-version[<ubuntu version or alias>]
#          \- pwncc-tag-version[<ubuntu version or alias>]
#         (pushes pwncc-<ubuntu version or alias>-v<pwnableharness version)
#  \- pwncc-push-default-version
#      \- pwncc-tag-default-version
#         (pushes pwncc-v<pwnableharness version>)
#  \- pwncc-push-latest
#      \- pwncc-push-latest[<ubuntu version or alias>]
#          \- pwncc-tag-latest[<ubuntu version or alias>]
#         (pushes pwncc-<ubuntu version or alias>)
#  \- pwncc-push-default-latest
#      \- pwncc-tag-default-latest
#         (pushes pwncc-latest)
#

$(call generate_dependency_list,pwncc-push-version,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call generate_dependency_list,pwncc-push-latest,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_targets, \
	pwncc-push \
	pwncc-push-version \
	pwncc-push-default-version \
	pwncc-push-latest \
	pwncc-push-default-latest \
)
$(call add_targets, \
	pwncc-push[<ubuntu-version>] \
	pwncc-push-latest[<ubuntu-version>] \
)

pwncc-push: pwncc-push-version
pwncc-push: pwncc-push-default-version
pwncc-push: pwncc-push-latest
pwncc-push: pwncc-push-default-latest
pwncc-push-version: pwncc-push-version[$(PWNCC_DEFAULT_BASE)]
pwncc-push-version: pwncc-push-version[$(PWNCC_DEFAULT_ALIAS)]
pwncc-push-latest: pwncc-push-latest[$(PWNCC_DEFAULT_BASE)]
pwncc-push-latest: pwncc-push-latest[$(PWNCC_DEFAULT_ALIAS)]

# (push pwncc-<ubuntu version or alias>-v<pwnableharness version)
pwncc-push-version[%]: pwncc-tag-version[%]
	$(_V)echo "Pushing tag 'pwncc-$*-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwncc-$*-$(PWNABLEHARNESS_VERSION)

# (push pwncc-v<pwnableharness version>)
pwncc-push-default-version: pwncc-tag-default-version
	$(_V)echo "Pushing tag 'pwncc-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwncc-$(PWNABLEHARNESS_VERSION)

# (push pwncc-<ubuntu version or alias>)
pwncc-push-latest[%]: pwncc-tag-latest[%]
	$(_V)echo "Pushing tag 'pwncc-$*' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwncc-$*

# (push pwncc-latest)
pwncc-push-default-latest: pwncc-tag-default-latest
	$(_V)echo "Pushing tag 'pwncc-latest' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwncc-latest


#
# Cleaning
#
# pwncc-clean
#  \- pwncc-clean-version
#      \- pwncc-clean-version[<ubuntu version or alias>]
#  \- pwncc-clean-default-version
#  \- pwncc-clean-latest
#      \- pwncc-clean-latest[<ubuntu version or alias>]
#  \- pwncc-clean-default-latest
#

$(call generate_dependency_list,pwncc-clean,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

$(call add_phony_targets, \
	pwncc-clean \
	pwncc-clean-version \
	pwncc-clean-default-version \
	pwncc-clean-latest \
	pwncc-clean-default-latest \
)
$(call add_targets, \
	pwncc-clean-version[<ubuntu-version>] \
	pwncc-clean-latest[<ubuntu-version>] \
)

pwncc-clean: pwncc-clean-version
pwncc-clean: pwncc-clean-default-version
pwncc-clean: pwncc-clean-latest
pwncc-clean: pwncc-clean-default-latest
pwncc-clean-version: pwncc-clean-version[$(PWNCC_DEFAULT_BASE)]
pwncc-clean-version: pwncc-clean-version[$(PWNCC_DEFAULT_ALIAS)]
pwncc-clean-latest: pwncc-clean-latest[$(PWNCC_DEFAULT_BASE)]
pwncc-clean-latest: pwncc-clean-latest[$(PWNCC_DEFAULT_ALIAS)]

# Remove pwncc-<ubuntu version>-v<pwnableharness version> tags and the build markers
$(patsubst %,pwncc-clean-version[%],$(UBUNTU_VERSIONS)): pwncc-clean-version[%]:
	$(_v)rm -f $(BUILD)/.pwncc_build_marker-$*
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove pwncc-<ubuntu-alias>-v<pwnableharness version> tags
$(patsubst %,pwncc-clean-version[%],$(UBUNTU_ALIASES)): pwncc-clean-version[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove pwncc-v<pwnableharness version> tag
pwncc-clean-default-version:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove pwncc-<ubuntu version or alias> tags
$(patsubst %,pwncc-clean-latest[%],$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES)): pwncc-clean-latest[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-$* \
		>/dev/null 2>&1 || true

# Remove pwncc-latest tag
pwncc-clean-default-latest:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-latest \
		>/dev/null 2>&1 || true

endif #C0deH4cker


ifdef CONFIG_USE_PWNCC

#####
# pwncc_prepare($1: project dir, $2: ubuntu version, $3: out_pwncc_cmd_prefix, $4: out_pwncc_deps)
#####
define _pwncc_prepare

$1+PREBUILD_SH := $$(wildcard $1/prebuild.sh)

ifdef $1+PREBUILD_SH
# Create a hash from:
#  - the project path
#  - prebuild.sh file contents
$1+PWNCC_MODIFIER := +$$(firstword $$(shell (echo '$1'; cat '$1/prebuild.sh') | shasum -a 256))
else #exists(DIR/prebuild.sh)
$1+PWNCC_MODIFIER :=
endif #exists(DIR/prebuild.sh)

$1+PWNCC_TAG_BASE := pwncc-$2-$$(PWNABLEHARNESS_VERSION)
$1+PWNCC_TAG := $$($1+PWNCC_TAG_BASE)$$($1+PWNCC_MODIFIER)

$4 :=
ifdef $1+PREBUILD_SH
# Return pwncc dependencies
$4 := $$($1+BUILD)/.$$($1+PWNCC_TAG)

ifndef PWNCC_TAG-$$($1+PWNCC_TAG)
PWNCC_TAG-$$($1+PWNCC_TAG) := 1

$$($4): $$($1+PREBUILD_SH) | $$(PWNCC_DIR)/pwncc.Dockerfile $$(PWNCC_DIR)/pwncc-prebuild.Dockerfile
	$$(_V)echo "Running $$< in pwncc container"
	$$(_v)$$(DOCKER) build \
			-f $$(PWNCC_DIR)/pwncc-prebuild.Dockerfile \
			--build-arg BASE_TAG=$$($1+PWNCC_TAG_BASE) \
			--build-arg DIR=$1 \
			-t $$(PWNABLEHARNESS_REPO):$$($1+PWNCC_TAG) \
		&& mkdir -p $$(@D) && touch $$@

endif #rule cache check
endif #exists(DIR/prebuild.sh)

ifdef CONTAINER_BUILD
$1+PWNCC_ARGS := \
	-v "$$(HOST_WORKSPACE)":/PwnableHarness/workspace \
	--workdir=/PwnableHarness/workspace/$1
else
$1+PWNCC_ARGS := \
	-v "$$(shell realpath '$$(ROOT_DIR)')":/PwnableHarness \
	--workdir=/PwnableHarness
endif

# Return pwncc command prefix
$3 := $$(DOCKER) run --rm \
	$$($1+PWNCC_ARGS) \
	$$(PWNABLEHARNESS_REPO):$$($1+PWNCC_TAG) \
	$$(SPACE)

endef #pwncc_prepare
pwncc_prepare = $(eval $(call _pwncc_prepare,$1,$2,$3,$4))
#####

endif #CONFIG_USE_PWNCC
