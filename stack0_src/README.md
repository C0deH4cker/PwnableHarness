## stack0

This challenge is intended to be a beginner's exploitation challenge.

It is a simple stack-based buffer overflow vulnerability, and the executable is
compiled without any vulnerability mitigations (ie there are no stack cookies and
the stack is executable).


To connect to this challenge, run the following:

    nc ctf.c0deh4cker.com 32101


This will connect you to the challenge running on my server.

There are two flags to be gained from this challenge. Also, the real flags are
different than the ones in the GitHub repo (lol nice try). To get the flags,
you must solve the following challenges:

1. Trick the program into thinking you purchased it.
2. Get a shell and read the second flag file.

Part 2 will require exploiting the service and getting a shell. The challenge
harness redirects all standard IO streams to the connected socket, so just
executing /bin/sh is good enough (ie no need to connect back to yourself). This
way, you don't have to open ports on your router or use a server.

I highly recommend downloading the challenge binary and running it on a local
linux system. If you have the docker engine already installed, the easiest way
to build and run this challenge is with docker. Otherwise, it can be built and
run manually.


## Docker method

    make docker-start

This will compile stack0, build the docker image, and run it with the correct
runtime parameters.


## Manual method

If you don't want to install the docker engine, stack0 can be run normally.
First, make sure you can build and run 32-bit executables:

    sudo dpkg --add-architecture i386
    sudo apt-get update && sudo apt-get install -y libc6:i386 gcc-multilib

Then, build PwnableHarness (run this in the root PwnableHarness directory):

    make && sudo make install

Next, build and run stack0 (run this in the stack0_src directory):

    make
    ./stack0 --no-chroot --user $USER --alarm 0


## Connecting to the locally running challenge

Either way you run it, stack0 will be listening on port 32101, so you can connect
to it with:

    nc localhost 32101


## Debugging your exploits

First, copy the process id of the stack0 server. If you ran it using docker, look
at the first line of output from running this command:

    docker logs stack0

While stack0 is listening for connections, open a root shell in the directory it's
running from. If you ran stack0 with the docker method, that means running:

    docker exec -it stack0 bash

You'll also need to install gdb if you're using the docker method or if you don't
already have gdb installed. Then, run the following to attach to the stack0 server
process and set a breakpoint that is hit when the challenge code starts:

    gdb stack0
    (gdb) attach <process id of stack0>
    (gdb) set follow-fork-mode child
    (gdb) b handle_connection
    (gdb) c

This first tells gdb what executable it should look at and then attaches to the
stack0 server process. Next, we tell gdb that when the process forks, it should
detach from the parent and attach to the newly created child process, which in
our case will be the process meant to handle connections from users and run the
actual challenge. Following this, we set a breakpoint on the `handle_connection`
function, which is defined in stack0.c and is the first challenge function called
once the server receives a connection. Finally, we continue execution and wait
for a connection to trigger the breakpoint.

Good luck!
