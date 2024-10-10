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

ifdef CONFIG_I_AM_C0DEH4CKER_HEAR_ME_ROAR

CONFIG_USE_PWNCC := 1

#
# Building
#
# pwncc-build
#  \- pwncc-build[<ubuntu-version>]
#      \- BUILD/.pwncc_build_marker-<ubuntu version>
#          (tags pwncc-<ubuntu version>-v<pwnableharness version)
#  \- pwncc-build[<ubuntu-alias>]
#      \- pwncc-tag[<ubuntu-alias>]
#

$(call add_phony_target,pwncc-build)
$(call generate_dependency_list,pwncc-build,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))

# Targets like pwncc-build[<ubuntu-version>] go through the rule below for .pwncc_build_marker-%
$(patsubst %,pwncc-build[%],$(UBUNTU_VERSIONS)): pwncc-build[%]: $(BUILD)/.pwncc_build_marker-%

define pwncc_build_template
$$(BUILD)/.pwncc_build_marker-$1: $$(PWNCC_DIR)/pwncc.Dockerfile | $$(ROOT_DIR)/VERSION
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
pwncc-build[$1]: pwncc-tag[$1]

endef #pwncc_build_alias_template
$(call generate_ubuntu_aliased_rules,pwncc_build_alias_template)
$(call add_target,pwncc-build[<ubuntu-version>])


#
# Tagging
#
# pwncc-tag
#  \- pwncc-tag[<ubuntu-version>]
#      \- pwncc-build[<ubuntu-version>]
#          (builds pwncc-<ubuntu-version>-v<pwnableharness version>)
#  \- pwncc-tag[<ubuntu-alias>]
#      (tags pwncc-<ubuntu-alias>-v<pwnableharness version>)
#

$(call add_phony_target,pwncc-tag)
$(call generate_dependency_list,pwncc-tag,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call add_target,pwncc-tag[<ubuntu-version>])

# pwncc-tag[<ubuntu-version>] is a nickname for pwncc-build[<ubuntu-version>]
$(patsubst %,pwncc-tag[%],$(UBUNTU_VERSIONS)): pwncc-tag[%]: pwncc-build[%]

# (tags pwncc-<ubuntu-alias>-v<pwnableharness version>)
define pwncc_tag_version_aliased_template

.PHONY: pwncc-tag[$1]
pwncc-tag[$1]: pwncc-build[$2]
	$$(_V)echo "Tagging Docker image with tag 'pwncc-$2-$$(PWNABLEHARNESS_VERSION)' as 'pwncc-$1-$$(PWNABLEHARNESS_VERSION)'"
	$$(_v)$$(DOCKER) tag \
		$$(PWNABLEHARNESS_REPO):pwncc-$2-$$(PWNABLEHARNESS_VERSION) \
		$$(PWNABLEHARNESS_REPO):pwncc-$1-$$(PWNABLEHARNESS_VERSION)

endef #pwncc_tag_version_aliased_template
$(call generate_ubuntu_aliased_rules,pwncc_tag_version_aliased_template)


#
# Pushing
#
# pwncc-push
#  \- pwncc-push-version[<ubuntu version or alias>]
#      \- pwncc-tag-version[<ubuntu version or alias>]
#      (pushes pwncc-<ubuntu version or alias>-v<pwnableharness version)
#

$(call add_phony_target,pwncc-push)
$(call generate_dependency_list,pwncc-push,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call add_target,pwncc-push[<ubuntu-version>])

# (push pwncc-<ubuntu version or alias>-v<pwnableharness version)
pwncc-push[%]: pwncc-tag[%]
	$(_V)echo "Pushing tag 'pwncc-$*-$(PWNABLEHARNESS_VERSION)' to $(PWNABLEHARNESS_REPO)"
	$(_v)$(DOCKER) push $(PWNABLEHARNESS_REPO):pwncc-$*-$(PWNABLEHARNESS_VERSION)


#
# Cleaning
#
# pwncc-clean
#  \- pwncc-clean[<ubuntu version or alias>]
#

$(call add_phony_target,pwncc-clean)
$(call generate_dependency_list,pwncc-clean,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES))
$(call add_target,pwncc-clean[<ubuntu-version>])

# Remove pwncc-<ubuntu version>-v<pwnableharness version> tags and the build markers
$(patsubst %,pwncc-clean[%],$(UBUNTU_VERSIONS)): pwncc-clean[%]:
	$(_v)rm -f $(BUILD)/.pwncc_build_marker-$* || true
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-$*-$(PWNABLEHARNESS_VERSION) \
		>/dev/null 2>&1 || true

# Remove pwncc-<ubuntu-alias>-v<pwnableharness version> tags
$(patsubst %,pwncc-clean[%],$(UBUNTU_ALIASES)): pwncc-clean[%]:
	$(_v)$(DOCKER) rmi -f \
		$(PWNABLEHARNESS_REPO):pwncc-$*-$(PWNABLEHARNESS_VERSION) \
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
	--workdir=/PwnableHarness/workspace
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
