## stack0

This challenge is intended to be a beginner's exploitation challenge.

It is a simple stack-based buffer overflow vulnerability, and the executable is
compiled without any vulnerability mitigations (no stack cookies, stack is
executable, etc).


To connect to this challenge, run the following:

    nc ctf.hackucf.org 32101


This will connect you to the challenge running on the Hack@UCF CTF server.

There are two flags to be gained from this challenge. Also, the real flags are
different than the ones in the GitHub repo (lol nice try). To get the flags,
you must solve the following challenges:

1. Trick the program into thinking you purchased it.
2. Get a shell and read the second flag file.

Part 2 will require exploiting the service and getting a shell. The challenge
harness redirects all standard IO streams to the connected socket, so just
executing `/bin/sh` is good enough (no need to connect back to yourself). This
way, you don't have to open ports on your router or use a server.

I highly recommend downloading the challenge binary and running it on a local
linux system, using `pwnmake docker-start` from this directory.


## Connecting to the locally running challenge

Either way you run it, stack0 will be listening on port 32101, so you can
connect to it with:

    nc localhost 32101

Good luck!
