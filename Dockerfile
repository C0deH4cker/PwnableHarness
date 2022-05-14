FROM ubuntu:16.04
LABEL maintainer="c0deh4cker@gmail.com"

# Add support for running 32-bit executables
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386 && rm -rf /var/lib/apt/lists/*

# Copy PwnableHarness libraries to /usr/local/lib
ARG BUILD_DIR
COPY $BUILD_DIR/libpwnableharness32.so $BUILD_DIR/libpwnableharness64.so /usr/local/lib/

# Copy pwnable server program to /usr/local/bin
COPY $BUILD_DIR/pwnableserver /usr/local/bin/

# Set privileges of everything
RUN chmod 0755 \
	/usr/local/lib/libpwnableharness32.so \
	/usr/local/lib/libpwnableharness64.so \
	/usr/local/bin/pwnableserver

# Just run bash shell when no command is given. This isn't intended
# to be a runnable docker image anyway
CMD /bin/bash


# CHALLENGE_NAME is the name of both the user and executable
ONBUILD ARG CHALLENGE_NAME
ONBUILD ENV CHALLENGE_NAME=$CHALLENGE_NAME

# Create the user this challenge runs as
ONBUILD RUN groupadd -g 1337 $CHALLENGE_NAME \
	&& useradd -m -s /bin/bash -u 1337 -g 1337 $CHALLENGE_NAME
ONBUILD WORKDIR /home/$CHALLENGE_NAME

# Add a fake flag file. When the challenge is run on the real server,
# the real flag file will be bind-mounted over top of the fake one.
ONBUILD ARG FLAG_DST=flag.txt
ONBUILD RUN \
	echo 'fakeflag{now_try_on_the_real_challenge_server}' > "$FLAG_DST" && \
	chown "root:$CHALLENGE_NAME" "$FLAG_DST" && \
	chmod 0640 "$FLAG_DST"

# Copy the executable to the new user's home directory. It
# will be owned and only writeable by root.
ONBUILD ARG CHALLENGE_PATH
ONBUILD COPY $CHALLENGE_PATH ./$CHALLENGE_NAME
ONBUILD RUN chmod 0755 $CHALLENGE_NAME

# Which port is exposed by this docker container
ONBUILD ARG PORT
ONBUILD ENV PORT=$PORT
ONBUILD EXPOSE $PORT

# Is there a time limit specified for this docker container?
ONBUILD ARG TIMELIMIT=0
ONBUILD ENV TIMELIMIT=$TIMELIMIT

# This allows adding the --inject argument which decides whether to
# inject a library into the target process.
ONBUILD ARG PWNABLESERVER_EXTRA_ARGS=
ONBUILD ENV PWNABLESERVER_EXTRA_ARGS=$PWNABLESERVER_EXTRA_ARGS

# Run the executable without a chroot since this is already running in a
# Docker container. Also specify the username explicitly in case the
# default is different.
ONBUILD ENTRYPOINT [ \
	"/bin/sh", \
	"-c", \
	"exec /usr/local/bin/pwnableserver --listen --no-chroot --alarm $TIMELIMIT --port $PORT --user $CHALLENGE_NAME --exec /home/$CHALLENGE_NAME/$CHALLENGE_NAME $PWNABLESERVER_EXTRA_ARGS" \
]
