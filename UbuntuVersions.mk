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
GLIBC_VERSIONS :=
include $(BUILD)/cached_ubuntu_versions.mk

# For now, this is a manual process by looking up versions from:
# https://repology.org/project/glibc/versions
# In the future, this could be improved to dynamically lookup the glibc
# version from each Ubuntu image. That would require pulling all the
# images though, so it should only be done in CI. Ideally, the supported
# Ubuntu versions check could also happen while building the `pwnmake`
# image, so it doesn't need to be done in each project again.

#####
# ubuntu_glibc($1: ubuntu version, $2: glibc version)
#
# Creates bidirectional mappings between glibc and Ubuntu OS versions
#####
define _ubuntu_glibc
UBUNTU_TO_GLIBC[$1] := $2
GLIBC_TO_UBUNTU[$2] := $1
GLIBC_VERSIONS += $2

ifdef UBUNTU_ALIAS_TO_VERSION[$1]
UBUNTU_TO_GLIBC[$$(UBUNTU_ALIAS_TO_VERSION[$1])] := $2
endif
endef
ubuntu_glibc = $(eval $(call _ubuntu_glibc,$1,$2))
#####
$(call ubuntu_glibc,14.04,2.19)
$(call ubuntu_glibc,16.04,2.23)
$(call ubuntu_glibc,18.04,2.27)
$(call ubuntu_glibc,20.04,2.31)
$(call ubuntu_glibc,22.04,2.35)
$(call ubuntu_glibc,23.04,2.37)
$(call ubuntu_glibc,23.10,2.38)
$(call ubuntu_glibc,24.04,2.39)
$(call ubuntu_glibc,24.10,2.40)


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
