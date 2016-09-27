## PwnableHarness

This project aims to make hosting pwnable CTF challenges easier. It provides a simple API that starts a forking socket server to handle inbound connections.

It is designed to be secure against hostile child processes. It accomplishes this in the following ways:

* The server runs as root and drops down to an unprivileged user to handle connections, so the child cannot kill the parent server process.
* When dropping privileges, care is taken to make sure that the privileges cannot be restored later.
* The service is chroot-ed to the home directory of the unprivileged user.
* Although Docker is not required to use PwnableHarness, it is highly recommended for its ease of use and added security.

Another feature of this project is that the server will redirect the child's stdin, stdout, and stderr to the socket upon receiving a connection.

The included `stack0` is a simple but real pwnable showing how to use this project. Look at its `Build.mk` and `Dockerfile` for documentation and examples of how these files should be created for use with PwnableHarness. For those curious, the `stack0` challenge is currently running on my server, but with the real flags rather than the fake ones included in this repo. For information about how to access this challenge, please read `stack0/README.md`.


### Usage

In order to create a new executable that uses PwnableHarness, first clone this project locally and build it:

    git clone https://github.com/C0deH4cker/PwnableHarness.git
    cd PwnableHarness
    make base

After it builds, make a subdirectory for your project. You'll need a `Build.mk` file and your source files:

    mkdir MyPwnable
    cd MyPwnable
    echo "TARGET := pwnable" > Build.mk
    cat << EOF > pwn_me.c
    #include <stdio.h>
    #include "pwnable_harness.h"
    
    void handle_connection(int sock) {
        printf("Hello, world!\n");
    }
    
    int main(int argc, char** argv) {
        server_options opts = {
            .user = "ctf_user",
            .chrooted = true,
            .port = 12345,
            .time_limit_seconds = 30
        };
        
        return server_main(argc, argv, opts, &handle_connection);
    }
    EOF
    cd ..

This creates everything necessary to build an executable using PwnableHarness. Running `make` from the top-level directory should build every subdirectory that contains a `Build.mk` file. To build only MyPwnable, run `make all[MyPwnable]`, which will build every target declared in `MyPwnable/Build.mk`.

If you want to build and run your executable with Docker, just add a line to `Build.mk` such as `DOCKER_PORTS := 12345`. This will tell the build system to bind port 12345 on the host to the Docker container for this executable, and it will also make the build system consider the Docker image to be runnable.

    echo "DOCKER_PORTS := 12345" >> MyPwnable/Build.mk

There are a handful of extremely handy commands for managing Docker images and containers with this build system. Every command can be run directly like `make docker-start` to apply the command to all projects in subdirectories that have a `Build.mk` file, or they can be run on a single image by including the DOCKER_IMAGE declared in `Build.mk` in the make target like `make docker-stop[c0deh4cker/stack0]`.

* `make docker-build`: Builds a Docker image for each subdirectory whose `Build.mk` defines `DOCKER_IMAGE`. This will also build the targets defined there if they aren't up to date.
* `make docker-rebuild`: Force rebuild a Docker image, even if none of the files it is built from have been modified.
* `make docker-start`: Start a Docker container running from this image.
* `make docker-restart`: Restart an already-started Docker container.
* `make docker-stop`: Stop a running Docker container.
* `make docker-clean`: Remove a running Docker container and its image.
