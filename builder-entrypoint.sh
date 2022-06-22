#!/bin/sh

# pwnmake also passes PWNMAKE_VERSION. For now, we don't do anything with it.

# Ensure that the Docker CLI with the same version as the Docker daemon on the
# host is downloaded to the docker-cli mount point.
docker_bin="/docker-cli/$DOCKER_VERSION"
if [ ! -f "$docker_bin"/docker ]; then
	# Delete old versions of the Docker CLI
	rm -rf /docker-cli/*
	mkdir "$docker_bin"
	
	# Download specific version of the Docker binaries and extract the CLI to /docker-cli/VERSION/docker
	# https://stackoverflow.com/a/43594065
	echo "Downloading Docker CLI version ${DOCKER_VERSION}..."
	(
		cd /docker-cli \
		&& curl -fsSLO "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
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

# Run PwnableHarness make command as the calling user
exec gosu pwnuser make -rR --warn-undefined-variables -f /PwnableHarness/Makefile "$@"
