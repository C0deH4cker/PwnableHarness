#!/bin/sh

docker_bin="/docker-cli/${DOCKER_VERSION}"

if [ ! -f "${docker_bin}"/docker ]; then
	# Delete old versions of the Docker CLI
	rm -rf /docker-cli/*
	mkdir "${docker_bin}"
	
	# Download specific version of the Docker binaries and extract the CLI to /usr/local/bin/docker
	# https://stackoverflow.com/a/43594065
	echo "Downloading Docker CLI version ${DOCKER_VERSION}..."
	(
		cd /docker-cli \
		&& curl -fsSLO "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
		&& tar xzf "docker-${DOCKER_VERSION}.tgz" --strip 1 \
			-C "${docker_bin}" docker/docker \
		&& rm "docker-${DOCKER_VERSION}.tgz"
	)
	echo "Done!"
fi

export PATH="${docker_bin}:$PATH"

# Create docker group so pwnuser can use the Docker socket
groupadd -r -o -g "${DOCKER_GID}" docker

# Create group and user for the caller (pwnuser:pwngroup)
groupadd -o -g "${CALLER_GID}" pwngroup
useradd -o -d /pwn -u "${CALLER_UID}" -g "${CALLER_GID}" -G docker -s /bin/bash pwnuser

# Run PwnableHarness make command as the calling user
gosu pwnuser make "$@"
