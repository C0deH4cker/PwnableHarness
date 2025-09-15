# The *_VERSION variables define what version is currently being created by this
# current source tree. The *_RELEASED variables track the last officially
# published release version (meaning it should be considered immutable now).
# Only during active development of a new version should *_VERSION be ahead of
# *_RELEASED.

# Update any time the PwnableHarness makefiles (or anything else in the pwnmake
# image) are changed.
PHMAKE_VERSION  := v2.3.1
PHMAKE_RELEASED := v2.3.1

# This only needs to update when there's a change that would affect the base
# images. Changes that only affect PwnableHarness as a build system don't need
# to update the base image version.
BASE_VERSION  := v2.1
BASE_RELEASED := v2.1

# This updates slower than PWNABLEHARNESS_VERSION. It's expected that a given
# pwncc version can be used by potentially many versions of PwnableHarness.
PWNCC_VERSION  := v2.2
PWNCC_RELEASED := v2.2
