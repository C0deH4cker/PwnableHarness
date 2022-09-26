#!/bin/sh

# pwnmake also passes PWNMAKE_VERSION. For now, we don't do anything with it.

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

if [ "$BUILDER_INIT" = "1" ]; then
	# Create group and user for the caller (pwnuser:pwngroup)
	groupadd -o -g "$CALLER_GID" pwngroup
	useradd -o -d /PwnableHarness/workspace -u "$CALLER_UID" -g "$CALLER_GID" -s /bin/bash pwnuser
	
	# Create docker group so pwnuser can use the Docker socket
	if [ -n "$DOCKER_GID" ]; then
		groupadd -r -o -g "$DOCKER_GID" docker
		usermod -aG docker pwnuser
	fi
	
	# Run builder preparation scripts from the workspace
	find . -name prebuild.sh -print0 | sort -z | DEBIAN_FRONTEND=noninteractive xargs -0 -n1 -r -t bash
	
	# Clear APT list cache to reduce image size in case one of the prebuild scripts installed packages
	rm -rf /var/lib/apt/lists/*
	
	# Exit because we were instructed to only perform initialization by BUILDER_INIT=1
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
	echo "WARNING: Changing permissions of /var/run/docker.sock (in the Docker Desktop VM) to be writeable by the $group_name group to workaround https://github.com/docker/for-mac/issues/6823" >&2
	chmod g+w /var/run/docker.sock
fi

# Run PwnableHarness make command as the calling user
exec gosu pwnuser make -rR --warn-undefined-variables -f /PwnableHarness/Makefile "$@"
