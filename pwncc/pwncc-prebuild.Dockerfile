ARG BASE_TAG
FROM c0deh4cker/pwnableharness:$BASE_TAG

ARG DIR
COPY $DIR/prebuild.sh /prebuild.sh
RUN /prebuild.sh && rm -rf /var/lib/apt/lists/*
