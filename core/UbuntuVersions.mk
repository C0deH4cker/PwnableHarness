# Generate cached_ubuntu_versions.mk file the first time only, to avoid
# delay from the network requests in every pwnmake command.
ifeq "$(wildcard $(BUILD)/cached_ubuntu_versions.mk)" ""
$(info Looking up currently supported Ubuntu versions...)
$(shell \
	mkdir -p $(BUILD) && \
	touch $(BUILD)/.dir && \
	python3 $(PWNABLEHARNESS_CORE_PROJECT)/get_supported_ubuntu_versions.py > $(BUILD)/cached_ubuntu_versions.mk.tmp && \
	mv $(BUILD)/cached_ubuntu_versions.mk.tmp $(BUILD)/cached_ubuntu_versions.mk \
	)
endif

UBUNTU_VERSIONS :=
UBUNTU_ALIASES :=
include $(BUILD)/cached_ubuntu_versions.mk

#####
# generate_dependency_list($1: base rule name, $2: parameter list)
#####
define _generate_dependency_list

# Add dependencies from the base rule name on the parameterized rule
$1: $$(foreach x,$2,$1[$$x])

# Mark base target and all parameterized targets as phony
.PHONY: $1 $$(foreach x,$2,$1[$$x])

endef #_generate_dependency_list
generate_dependency_list = $(eval $(call _generate_dependency_list,$1))
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
