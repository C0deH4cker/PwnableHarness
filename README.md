## PwnableHarness

This project aims to make hosting pwnable CTF challenges easier. It provides a single, API that starts a forking socket server to handle inbound connections.

It is designed to be secure against a hostile child process. It accompilshes this in the following ways:

* The server runs as root and drops down to an unprivileged user to handle connections, so the child cannot kill the parent server process.
* When dropping privileges, care is taken to make sure that the privileges cannot be restored later.
* Child processes are chroot-ed to the home directory of the unprivileged user.

Another feature of this project is that the server will redirect the child's stdin, stdout, and stderr to the socket upon receiving a connection. In the future, this might be an option rather than the default behavior.

The included `stack0.c` is a very simple pwnable showing how to use this project. It is currently running on my server, and can be found at http://ctf.c0deh4cker.com/stack0.
