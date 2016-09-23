FROM c0deh4cker/pwnableharness
MAINTAINER C0deH4cker <c0deh4cker@gmail.com>
COPY flag*.txt ./
RUN chown root:$RUNTIME_NAME flag*.txt && chmod 0640 flag*.txt
EXPOSE 32101
