FROM ubuntu:16.04
LABEL maintainer="c0deh4cker@gmail.com"

# Add support for running 32-bit executables
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386 && rm -rf /var/lib/apt/lists/*

# Copy PwnableHarness libraries to /usr/local/lib
ARG BUILD_DIR
COPY $BUILD_DIR/libpwnableharness32.so $BUILD_DIR/libpwnableharness64.so /usr/local/lib/

# Copy preload libraries to their respective $LIB paths
COPY $BUILD_DIR/pwnablepreload32.so /lib/i386-linux-gnu/pwnablepreload.so
COPY $BUILD_DIR/pwnablepreload64.so /lib/x86_64-linux-gnu/pwnablepreload.so

# Copy pwnable server program to /usr/local/bin
COPY $BUILD_DIR/pwnableserver /usr/local/bin/

# Set privileges of everything
RUN chmod 0755 \
	/usr/local/lib/libpwnableharness32.so \
	/usr/local/lib/libpwnableharness64.so \
	/lib/i386-linux-gnu/pwnablepreload.so \
	/lib/x86_64-linux-gnu/pwnablepreload.so \
	/usr/local/bin/pwnableserver

# Just run bash shell when no command is given. This isn't intended
# to be a runnable docker image anyway
CMD /bin/bash


# CHALLENGE_NAME is the name of both the user and executable
ONBUILD ARG CHALLENGE_NAME
ONBUILD ENV CHALLENGE_NAME=$CHALLENGE_NAME

# Create the user this challenge runs as
ONBUILD RUN useradd -m -s /bin/bash -U $CHALLENGE_NAME

# Copy the executable to the new user's home directory. It
# will be owned and only writeable by root.
ONBUILD WORKDIR /home/$CHALLENGE_NAME
ONBUILD ARG CHALLENGE_PATH
ONBUILD COPY $CHALLENGE_PATH ./$CHALLENGE_NAME
ONBUILD RUN chmod 0755 $CHALLENGE_NAME

# If given a flag, write it to the given destination file
ONBUILD ARG FLAG=
ONBUILD ARG FLAG_DST=flag.txt
ONBUILD RUN if [ -n "$FLAG" -a -n "$FLAG_DST" ]; then \
		echo "$FLAG" > "$FLAG_DST" && \
		chown "root:$CHALLENGE_NAME" "$FLAG_DST" && \
		chmod 0640 "$FLAG_DST"; \
	fi

# Which port is exposed by this docker container
ONBUILD ARG PORT
ONBUILD ENV PORT=$PORT
ONBUILD EXPOSE $PORT

# Is there a time limit specified for this docker container?
ONBUILD ARG TIMELIMIT=0
ONBUILD ENV TIMELIMIT=$TIMELIMIT

# Run the executable without a chroot since this is already running in a
# Docker container. Also specify the username explicitly in case the
# default is different. We inject the pwnablepreload.so library into the
# spawned challenge process to set the buffering mode of stdout & stderr
# to unbuffered.
ONBUILD ENTRYPOINT [ \
	"/bin/sh", \
	"-c", \
	"exec /usr/local/bin/pwnableserver --listen --no-chroot --alarm $TIMELIMIT --port $PORT --user $CHALLENGE_NAME --inject '/$LIB/pwnablepreload.so' --exec /home/$CHALLENGE_NAME/$CHALLENGE_NAME" \
]
