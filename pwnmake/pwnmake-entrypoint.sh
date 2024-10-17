#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/a/4025065
_vercmp() {
	if [[ $1 == $2 ]]
	then
		return 0
	fi
	local IFS=.
	local i ver1=($1) ver2=($2)
	# Fill empty fields in ver1 with zeros
	for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
	do
		ver1[i]=0
	done
	for ((i=0; i<${#ver1[@]}; i++))
	do
		if ((10#${ver1[i]:=0} > 10#${ver2[i]:=0}))
		then
			return 1
		fi
		if ((10#${ver1[i]} < 10#${ver2[i]}))
		then
			return 2
		fi
	done
	return 0
}

vercmp() {
	_vercmp "$1" "$3"
	case $? in
	0)
		case "$2" in
			"=="|"<="|">="|"-eq"|"-le"|"-ge") return 0;;
		esac
		;;
	1)
		case "$2" in
			">"|">="|"-gt"|"-ge") return 0;;
		esac
		;;
	2)
		case "$2" in
			"<"|"<="|"-lt"|"-le") return 0;;
		esac
		;;
	esac
	
	return 1
}

if [ -n "${PWNMAKE_VERBOSE:-}" ]; then
	set -x
fi

# Version 2.1 has breaking changes that require cooperation between the pwnmake
# script and the pwnmake image.
PWNMAKE_VERSION_MIN=2.1
if vercmp "$PWNMAKE_VERSION" -lt "$PWNMAKE_VERSION_MIN"; then
	echo "Your pwnmake script is out of date!" >&2
	echo "Installed version: $PWNMAKE_VERSION" >&2
	echo "Minimum required version: $PWNMAKE_VERSION_MIN" >&2
	exit 1
fi

# Ensure that the Docker CLI with the same version as the Docker daemon on the
# host is downloaded to the docker-cli mount point.
docker_version_dir="/docker-cli/$DOCKER_VERSION"
docker_bin="$docker_version_dir/${DOCKER_ARCH:=amd64}"
if [ ! -f "$docker_bin/docker" ]; then
	if [ ! -d "$docker_version_dir" ]; then
		# Delete old versions of the Docker CLI
		rm -rf /docker-cli/*
	fi
	mkdir -p "$docker_bin"
	
	case "$DOCKER_ARCH" in
	arm64)   DL_ARCH=aarch64 ;;
	amd64|*) DL_ARCH=x86_64 ;;
	esac
	
	# Download specific version of the Docker binaries and extract the CLI to /docker-cli/VERSION/ARCH/docker
	# https://stackoverflow.com/a/43594065
	echo "Downloading Docker CLI version ${DOCKER_VERSION} for ${DL_ARCH}..."
	(
		cd /docker-cli \
		&& curl -fsSLO "https://download.docker.com/linux/static/stable/${DL_ARCH}/docker-${DOCKER_VERSION}.tgz" \
		&& tar xzf "docker-${DOCKER_VERSION}.tgz" --strip 1 \
			-C "$docker_bin" docker/docker \
		&& rm "docker-${DOCKER_VERSION}.tgz"
	)
	echo "Done!"
fi
export PATH="$docker_bin:$PATH"

if [ "$PWNMAKE_INIT" = "1" ]; then
	# Create group and user for the caller (pwnuser:pwngroup)
	groupadd -o -g "$CALLER_GID" pwngroup
	useradd -o -d /PwnableHarness/workspace -K UID_MIN=0 -u "$CALLER_UID" -g "$CALLER_GID" -s /bin/bash pwnuser
	
	# Create docker group so pwnuser can use the Docker socket
	if [ -n "$DOCKER_GID" ]; then
		groupadd -r -o -g "$DOCKER_GID" docker
		usermod -aG docker pwnuser
	fi
	
	# Run pwnmake preparation scripts from the workspace
	find . -name prebuild.sh -print0 | sort -z | xargs -0 -n1 -r -t bash
	
	# Clear APT list cache to reduce image size in case one of the prebuild scripts installed packages
	rm -rf /var/lib/apt/lists/*
	
	# Exit because we were instructed to only perform initialization
	exit 0
fi

# https://github.com/docker/for-mac/issues/6823
# Now they've really gone and done it......
# This issue (regression in Docker 4.19.0) makes even the workaround,
# /var/run/docker.sock.raw, be owned by root:root with permissions
# rwx-r-xr-x. So now there's actually no way to contact the Docker
# socket without being the root user. But of course, running the build
# commands as the root user will make the resulting files be owned by
# root, which is absolutely not what is desired here. Therefore, from
# Docker 4.19.0 onwards, until this issue is resolved, the new workaround
# will be to chmod the docker socket on macOS. While this is admittedly
# heavy-handed, it's the best solution to the problem at hand.
#
# UPDATE: Fixed in 4.21.1: https://github.com/docker/for-mac/issues/6823#issuecomment-1618851919
group_write=$(stat --printf '%A' /var/run/docker.sock | tail -c5 | head -c1)
if [ "$group_write" != "w" ]; then
	group_name=$(stat --printf '%G' /var/run/docker.sock)
	echo "WARNING: Changing permissions of /var/run/docker.sock (in the Docker Desktop VM) to be writeable by the $group_name group as a workaround for https://github.com/docker/for-mac/issues/6823" >&2
	chmod g+w /var/run/docker.sock
fi

# Run PwnableHarness make command as the calling user
exec "$@"
