FROM ubuntu:16.04
LABEL maintainer="c0deh4cker@gmail.com"

# Add support for running 32-bit executables
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386

# Copy PwnableHarness libraries to /usr/local/lib
COPY libpwnableharness32.so libpwnableharness64.so /usr/local/lib/

# Just run bash shell when no command is given. This isn't intended
# to be a runnable docker image anyway
CMD /bin/bash


# RUNTIME_NAME is the name of both the user and executable
ONBUILD ARG RUNTIME_NAME
ONBUILD ENV RUNTIME_NAME=$RUNTIME_NAME

# Create the user this challenge runs as
ONBUILD RUN useradd -m -s /bin/bash -U $RUNTIME_NAME

# Copy the executable to the new user's home directory. It
# will be owned and only writeable by root.
ONBUILD WORKDIR /home/$RUNTIME_NAME
ONBUILD COPY $RUNTIME_NAME ./

# If given a flag, write it to the given destination file
ONBUILD ARG FLAG=
ONBUILD ARG FLAG_DST=flag.txt
ONBUILD RUN if [ -n "$FLAG" -a -n "$FLAG_DST" ]; then \
		echo "$FLAG" > "$FLAG_DST" && \
		chown "root:$RUNTIME_NAME" "$FLAG_DST" && \
		chmod 0640 "$FLAG_DST"; \
	fi

# Which ports are exposed by this docker container
ONBUILD ARG PORTS
ONBUILD EXPOSE $PORTS

# Run the executable without a chroot since this is already
# running in a docker container. Also specify the username
# explicitly in case the default is different.
ONBUILD ENTRYPOINT [ \
	"/bin/sh", \
	"-c", \
	"exec /home/$RUNTIME_NAME/$RUNTIME_NAME --listen --no-chroot --user $RUNTIME_NAME" \
]
