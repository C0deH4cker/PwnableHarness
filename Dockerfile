FROM ubuntu
MAINTAINER C0deH4cker <c0deh4cker@gmail.com>
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386
COPY *.so /usr/local/lib/
ONBUILD ARG RUNTIME_NAME
ONBUILD ENV RUNTIME_NAME=$RUNTIME_NAME
ONBUILD RUN useradd -m -s /bin/bash -U $RUNTIME_NAME
ONBUILD WORKDIR /home/$RUNTIME_NAME
ONBUILD COPY $RUNTIME_NAME ./
ONBUILD CMD /home/$RUNTIME_NAME/$RUNTIME_NAME --no-chroot --user $RUNTIME_NAME
