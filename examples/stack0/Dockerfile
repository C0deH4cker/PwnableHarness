FROM c0deh4cker/pwnableharness
LABEL maintainer=c0deh4cker@gmail.com

# Allow passing docker build args for the source paths
# in order to copy the real flag files if they exist.
ARG FLAG1=flag1.txt
ARG FLAG2=flag2.txt
ENV FLAG1=$FLAG1 FLAG2=$FLAG2

# Copy both flags to the current directory of the challenge.
COPY $FLAG1 flag1.txt
COPY $FLAG2 flag2.txt

# Make the flag readable only by root or the challenge's group.
RUN chown root:$RUNTIME_NAME flag*.txt && chmod 0640 flag1.txt flag2.txt
