# Check if there's a cached_ubuntu_versions.mk shipped in this pwnmake image
ifneq "$(wildcard $(ROOT_DIR)/cached_ubuntu_versions.mk)" ""
include $(ROOT_DIR)/cached_ubuntu_versions.mk
else #!exists(ROOT_DIR/cached_ubuntu_versions.mk)

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

ifeq "$(wildcard /etc/lsb-release)" ""
LAUNCHPADLIB_PREFIX := pwnmake --shell --$(SPACE)
else #IS_LINUX
LAUNCHPADLIB_PREFIX :=
endif #IS_LINUX

$(shell \
	$(_VSH) \
	mkdir -p $(BUILD) && \
	touch $(BUILD)/.dir && \
	$(LAUNCHPADLIB_PREFIX)python3 get_supported_ubuntu_versions.py > $(BUILD)/cached_ubuntu_versions.mk.tmp && \
	mv $(BUILD)/cached_ubuntu_versions.mk.tmp $(BUILD)/cached_ubuntu_versions.mk || \
	rm -f $(BUILD)/cached_ubuntu_versions.mk.tmp \
	)

endif #clean not in MAKECMDGOALS
endif #!exists(BUILD/cached_ubuntu_versions.mk)
include $(BUILD)/cached_ubuntu_versions.mk
endif #!exists(ROOT_DIR/cached_ubuntu_versions.mk)


ifneq "$(wildcard $(ROOT_DIR)/cached_glibc_versions.mk)" ""
include $(ROOT_DIR)/cached_glibc_versions.mk
else #!exists(ROOT_DIR/cached_glibc_versions.mk)

$(BUILD)/.glibc_message_%.txt: | $(BUILD)/.dir
	$(_v)$(DOCKER) run --platform=linux/amd64 --rm ubuntu:$* \
		/lib64/ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/libc.so.6 > $@

$(BUILD)/.glibc_%.mk: $(BUILD)/.glibc_message_%.txt
	$(_v)echo "UBUNTU_TO_GLIBC[$*] := $$(sed -nE 's/.*release version ([0-9]+\.[0-9]+).*/\1/p' $<)" > $@

$(BUILD)/cached_glibc_versions.mk: $(foreach ubu,$(UBUNTU_VERSIONS),$(BUILD)/.glibc_$(ubu).mk)
	$(_v)cat $^ | sort > $@

include $(BUILD)/cached_glibc_versions.mk
endif #!exists(ROOT_DIR/cached_glibc_versions.mk)

#####
# ubuntu_glibc($1: ubuntu version)
#
# Creates bidirectional mappings between glibc and Ubuntu OS versions
#####
define _ubuntu_glibc
ifdef UBUNTU_TO_GLIBC[$1]

GLIBC_TO_UBUNTU[$$(UBUNTU_TO_GLIBC[$1])] := $1
GLIBC_VERSIONS += $$(UBUNTU_TO_GLIBC[$1])

ifdef UBUNTU_VERSION_TO_ALIAS[$1]
UBUNTU_TO_GLIBC[$$(UBUNTU_VERSION_TO_ALIAS[$1])] := $$(UBUNTU_TO_GLIBC[$1])
endif

endif #UBUNTU_TO_GLIBC[version]
endef
ubuntu_glibc = $(eval $(call _ubuntu_glibc,$1))
#####
GLIBC_VERSIONS :=
$(foreach ubu,$(UBUNTU_VERSIONS),$(call ubuntu_glibc,$(ubu)))


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
