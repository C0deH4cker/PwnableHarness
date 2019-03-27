PwnableHarness
=====

PwnableHarness is:

* Primarily intended for running pwnable CTF challenges that communicate over stdin/stdout and serving them on a listening TCP socket bound to a port.
* A C/C++ build system.
  * Supports 32-bit and 64-bit builds
  * Makes selectively enabling individual compiler mitigations like ASLR and NX easy
  * Safe to run in parallel for faster builds (by passing `-j<number of jobs>` to make, e.g. `make -j8`)
  * Allows automatically publishing any source files or build products you choose to a directory such as `/var/www/`
* A Docker image and container management system.
  * No Dockerfile needed, though you may provide your own for customization
  * Automatically manages tricky settings like port forwarding
  * This is opt-in, so feel free to use PwnableHarness to build and publish RE challenges as well!
* Secure by default.
* Easy to use!


### Quickstart

Please refer to the [`FlagCharity`](examples/FlagCharity) example. This is a minimal yet complete example program showing how to use PwnableHarness. When running this challenge, PwnableHarness will create a TCP server program listening on the requested port that runs a new process of the `charity` program upon receiving each new incoming connection, and its stdin/stdout/stderr are all redirected to this TCP socket. Line buffering is disabled for stdout/stderr, so you don't need to insert calls to `fflush(stdout)` after each `printf()` to ensure the text will be sent.


### Useful Commands

* `make`: Build all custom challenges.
* `make WITH_EXAMPLES=1`: Build all custom challenges and example challenges.
* `make -j8`: Build all custom challenges with 8 parallel jobs.
* `make VERBOSE=1`: Build all custom challenges in verbose mode by printing the exact commands run instead of simple explanations.
* `make publish`: Copy all source files and build artifacts that are declared to be published in `Build.mk` files to the `PwnableHarness/publish` directory or symlink to a directory (such as `/var/www`).
* `make docker-build`: Builds a Docker image for each subdirectory whose `Build.mk` defines `DOCKER_IMAGE`. This will also build the targets defined there if they aren't up to date.
* `make docker-rebuild`: Force rebuild each Docker image, even if none of the files it is built from have been modified.
* `make docker-start`: Create and start a Docker container from each image, building any Docker images necessary.
* `make docker-restart`: Restart all Docker containers (only containers defined under PwnableHarness).
* `make docker-stop`: Stop all running Docker containers (only containers defined under PwnableHarness).
* `make docker-clean`: Remove all running Docker containers and Docker images (only containers and images defined under PwnableHarness).
* `make clean docker-clean all docker-build docker-start publish -j8`: Stop all containers, rebuild all challenges and Docker images, redeploy all Docker containers, and publish updated artifacts with 8 parallel jobs!

Every command can be run directly like `make docker-start` to apply the command to all projects in subdirectories that have a `Build.mk` file, or they can be run on a single image by including the DOCKER_IMAGE declared in `Build.mk` in the make target like `make docker-stop[c0deh4cker/stack0]`. An individual project directory can be built by using `make all[examples/FlagCharity]` or published using `make publish[examples/stack0]`.


### Security

PwnableHarness assumes that the challenge process will be compromised, as that is often the point of pwnable CTF challenges. Therefore, PwnableHarness aims to allow this in the safest way possible by preventing compromised challenge processes from doing anything malicious. The security of challenges deployed under PwnableHarness is layered and works as follows:

* The server runs under a Docker container, isolating the deployed challenge against other challenges and the host, even in the unlikely event that the root pwnable server process is compromised.
* The pwnable server program runs as root and drops down to an unprivileged user to handle connections, so the child cannot kill the parent server process.
* When dropping privileges, care is taken to make sure that the privileges cannot be restored later.


### Documentation for Build.mk Settings

Refer to the stack0 example challenge's [`Build.mk`](examples/stack0/Build.mk), which documents every supported build variable.


### Usage and Deployment

PwnableHarness challenges are often developed in their own repos or as directories within larger repos containing many challenges, some of which may not even be PwnableHarness challengs. Challenges should be modelled after the included [`FlagCharity`](examples/FlagCharity) example. PwnableHarness will recursively look through all child directories. Any directory that contains a `Build.mk` file is considered a PwnableHarness project directory. Here is how to set up your challenges repo to build under PwnableHarness:

  * Clone your challenge repo (referred to as MyChallenges) alongside PwnableHarness. As an example, they may be located at `~/MyChallenges/` and `~/PwnableHarness/`.
  * In the PwnableHarness directory, create a symlink to your challenges directory: `cd PwnableHarness; ln -s ../MyChallenges .`
  * Optionally, create a folder/symlink in the PwnableHarness repo called `publish` where files declared to be published will be copied.
  * Ready to go! `make all docker-build docker-start publish -j8`, or any other PwnableHarness commands.


### SunshineCTF

The SunshineCTF competition has used PwnableHarness to build, manage, and deploy all pwnable challenges since 2017. Note that these PwnableHarness challenges all use the old-style that linked directly against libpwnableharness. The pwn challenges in SunshineCTF 2019 use the new style, and they will be open-sourced on GitHub in April 2019.

* [SunshineCTF-2017-Public](https://github.com/HackUCF/SunshineCTF-2017-Public)
* [SunshineCTF-2018-Public](https://github.com/HackUCF/SunshineCTF-2018-Public)
