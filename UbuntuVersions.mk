# Generate cached_ubuntu_versions.mk file the first time only, to avoid
# delay from the network requests in every pwnmake command.
ifeq "$(wildcard $(BUILD)/cached_ubuntu_versions.mk)" ""

ifeq "$(filter clean,$(MAKECMDGOALS))" ""

ifdef VERBOSE
_VSH := set -x &&
else #VERBOSE
_VSH :=
$(info Looking up currently supported Ubuntu versions...)
endif #VERBOSE

$(shell \
	$(_VSH) \
	mkdir -p $(BUILD) && \
	touch $(BUILD)/.dir && \
	python3 $(ROOT_DIR)/get_supported_ubuntu_versions.py > $(BUILD)/cached_ubuntu_versions.mk.tmp && \
	mv $(BUILD)/cached_ubuntu_versions.mk.tmp $(BUILD)/cached_ubuntu_versions.mk \
	)

endif #clean not in MAKECMDGOALS
endif #!exists(cached_ubuntu_versions.mk)

UBUNTU_VERSIONS :=
UBUNTU_ALIASES :=
include $(BUILD)/cached_ubuntu_versions.mk

# For now, this is a manual process by looking up versions from:
# https://repology.org/project/glibc/versions
# In the future, this could be improved to dynamically lookup the glibc
# version from each Ubuntu image. That would require pulling all the
# images though, so it should only be done in CI. Ideally, the supported
# Ubuntu versions check could also happen while building the `pwnmake`
# image, so it doesn't need to be done in each project again.

#####
# glibc_ubuntu($1: glibc version, $2: ubuntu version)
#
# Creates bidirectional mappings between glibc and Ubuntu OS versions
#####
define _glibc_ubuntu
GLIBC_TO_UBUNTU[$1] := $2
UBUNTU_TO_GLIBC[$2] := $1

ifdef UBUNTU_ALIAS_TO_VERSION[$2]
UBUNTU_TO_GLIBC[$$(UBUNTU_ALIAS_TO_VERSION[$2])] := $1
endif
endef
glibc_ubuntu = $(eval $(call _glibc_ubuntu,$1,$2))
#####
$(call glibc_ubuntu,2.19,14.04)
$(call glibc_ubuntu,2.23,16.04)
$(call glibc_ubuntu,2.27,18.04)
$(call glibc_ubuntu,2.31,20.04)
$(call glibc_ubuntu,2.35,22.04)
$(call glibc_ubuntu,2.37,23.04)
$(call glibc_ubuntu,2.38,23.10)
$(call glibc_ubuntu,2.39,24.04)
$(call glibc_ubuntu,2.40,24.10)


#####
# generate_dependency_list($1: base rule name, $2: parameter list)
#####
define _generate_dependency_list

# Add dependencies from the base rule name on the parameterized rule
$1: $$(foreach x,$2,$1[$$x])

endef #_generate_dependency_list
generate_dependency_list = $(eval $(call _generate_dependency_list,$1,$2))
#####

#####
# generate_ubuntu_versioned_rules($1: rule_function($1: ubuntu version))
#####
generate_ubuntu_versioned_rules = $(foreach _vers,$(UBUNTU_VERSIONS),$(eval $(call $1,$(_vers))))
#####

#####
# generate_ubuntu_aliased_rules($1: rule_function($1: ubuntu alias name, $2: ubuntu version))
#####
generate_ubuntu_aliased_rules = $(foreach _alias,$(UBUNTU_ALIASES),$(eval $(call $1,$(_alias),$(UBUNTU_ALIAS_TO_VERSION[$(_alias)]))))
#####

####
# generate_ubuntu_both_rules($1: rule_function($1: ubuntu version or alias))
#####
generate_ubuntu_both_rules = $(foreach _vers_or_alias,$(UBUNTU_VERSIONS) $(UBUNTU_ALIASES),$(eval $(call $1,$(_vers_or_alias))))
#####
