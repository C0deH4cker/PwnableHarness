ARG BASE_TAG=pwncc-24.04-v2.1
FROM c0deh4cker/pwnableharness:$BASE_TAG

ARG DIR
COPY $DIR/prebuild.sh /prebuild.sh
RUN /bin/bash /prebuild.sh && rm -rf /var/lib/apt/lists/*
