PwnableHarness: C/C++ build and Docker management system for CTF challenges
=====

PwnableHarness is:

* Primarily intended for running pwnable CTF challenges that communicate over
  stdin/stdout and serving them on a listening TCP socket bound to a port.
* A C/C++ build system.
  * Supports 32-bit and 64-bit builds
  * Makes selectively enabling individual compiler mitigations like ASLR and NX easy
  * Safe to run in parallel for faster builds (by passing `-j<number of jobs>`
    to make, e.g. `make -j8`)
  * Allows automatically publishing any source files or build products you choose
* A Docker image and container management system.
  * No Dockerfile needed, though you may provide your own for customization
  * Automatically manages tricky settings like port forwarding
  * This is opt-in, so feel free to use PwnableHarness to build and publish RE
    challenges as well!
* Secure by default.
* Easy to use!


### The `pwnmake` command

Make sure you have Docker installed. Then:

1. Script-only installation

```bash
sudo curl -sSLo /usr/local/bin/pwnmake https://raw.githubusercontent.com/C0deH4cker/PwnableHarness/master/bin/pwnmake
sudo chmod +x /usr/local/bin/pwnmake
```

2. Git installation

```bash
git clone https://github.com/C0deH4cker/PwnableHarness.git
cd PwnableHarness
echo "export PATH=\"\$PATH:$(pwd)/bin\"" >> ~/.bash_profile
export PATH="$PATH:$(pwd)/bin"
```

The `pwnmake` command acts like `make`, except it runs all `make` commands in a
special Docker container that has PwnableHarness embedded within. Your workspace
directory (current working directory by default) is automatically mounted in the
container as well. This effectively allows you to build PwnableHarness projects
anywhere in your filesystem without them needing to be placed in a subdirectory
of a clone of the PwnableHarness repo. It also allows building and running Linux
challenges on macOS. Furthermore, using `pwnmake` is much more portable, as it
uses the compilers from the `pwnmake` image instead of whichever version of `gcc`
or `clang` you have installed on your host.

The `pwnmake` command has some extra options (see `pwnmake --help`). Most of the
time, none of these will be necessary.


### Quickstart

Please refer to the [`FlagCharity`](examples/FlagCharity) example. This is a minimal
yet complete example program showing how to use PwnableHarness. When running this
challenge, PwnableHarness will create a TCP server program listening on the requested
port that runs a new process of the `charity` program upon receiving each new incoming
connection, and its stdin/stdout/stderr are all redirected to this TCP socket. Line
buffering is disabled for stdout/stderr, so you don't need to insert calls to
`fflush(stdout)` after each `printf()` to ensure the text will be sent.

To try out the examples, clone the PwnableHarness repo and `cd` into the examples
directory. Then, just run `pwnmake` (after installing it using the above directions)
to build the challenges! You can also do `pwnmake deploy` to start the challenge
containers. Then, use `docker ps` to check that they're running and see the ports
that they listen on. For `FlagCharity`, you can connect to the locally running
challenge server with `nc localhost 19891`.


### Useful Commands

* `pwnmake`: Build all custom challenges.
* `pwnmake -j8`: Build all custom challenges with 8 parallel jobs.
* `pwnmake VERBOSE=1`: Build all custom challenges in verbose mode by printing the
  exact commands run instead of simple explanations.
* `pwnmake publish`: Copy all source files and build artifacts that are declared to
  be published in `Build.mk` files to publish directory in the workspace.
* `pwnmake docker-build`: Builds a Docker image for each subdirectory whose `Build.mk`
  defines `DOCKER_IMAGE`. This will also build the targets defined there if they
  aren't up to date.
* `pwnmake docker-rebuild`: Force rebuild each Docker image, even if none of the files
  it is built from have been modified.
* `pwnmake docker-start`: Create and start a Docker container from each image,
  building any Docker images necessary.
* `pwnmake docker-restart`: Restart all Docker containers (only containers defined
  in the workspace).
* `pwnmake docker-stop`: Stop all running Docker containers (only containers defined
  in the workspace).
* `pwnmake docker-clean`: Remove all running Docker containers and Docker images
  (only containers and images defined in the workspace).
* `pwnmake clean docker-clean all docker-build docker-start publish -j8`: Stop all
  containers, rebuild all challenges and Docker images, redeploy all Docker containers,
  and publish updated artifacts with 8 parallel jobs!

Every command can be run directly like `pwnmake docker-start` to apply the
command to all projects in the workspace, or they can be run on a single image
by including the `DOCKER_IMAGE` declared in `Build.mk` in the make target like
`pwnmake docker-stop[charity]`. An individual project directory can be built by
using `pwnmake all[FlagCharity]` or published using `pwnmake publish[stack0]`.

For extra documentation on the available targets and command-line variables, see
the output of [`pwnmake help`](MakeTargets.md).


### Security

PwnableHarness assumes that the challenge process will be compromised, as that
is often the point of pwnable CTF challenges. Therefore, PwnableHarness aims to
allow this in the safest way possible by preventing compromised challenge
processes from doing anything malicious. The security of challenges deployed
under PwnableHarness is layered and works as follows:

* The server runs under a Docker container, isolating the deployed challenge
  against other challenges and the host, even in the unlikely event that the
  root pwnable server process is compromised.
* The pwnable server program runs as root and drops down to an unprivileged
  user to handle connections, so the child cannot kill the parent server process.
* When dropping privileges, care is taken to make sure that the privileges
  cannot be restored later.


### Documentation for `Build.mk` Settings

Refer to the stack0 example challenge's [`Build.mk`](examples/stack0/Build.mk),
which documents every supported build variable.


### Usage and Deployment

PwnableHarness challenges are often developed in their own repos or as directories
within larger repos containing many challenges, some of which may not even be
PwnableHarness challengs. Challenges should be modelled after the included
[`FlagCharity`](examples/FlagCharity) example. PwnableHarness will recursively look
through all child directories. Any directory that contains a `Build.mk` file is
considered a PwnableHarness project directory. After installing the `pwnmake`
command, just run it from any directory to recursively build all PwnableHarness
projects within! A convenient command is `pwnmake deploy -j8`, which will compile
all source code, build Docker containers, start them, and publish all desired files
in parallel with 8 worker processes.


### SunshineCTF

The [SunshineCTF](https://sunshinectf.org/) competition has used PwnableHarness to
build, manage, and deploy all pwnable challenges since 2017. Note that before 2019,
SunshineCTF used the old style of PwnableHarness where challenge binaries linked
directly against `libpwnableharness(32|64).so`. The pwn challenges in SunshineCTF
2019 and forwards use the new style. The 2019 repo also serves as an example of how
PwnableHarness can be used to manage challenges that aren't exploitation challenges
or even written in C, as the web challenges are managed by PwnableHarness, such as
the Docker image building, container running, and even Nginx config management.
All SunshineCTF repos before 2022 were managed using `make` directly rather than
using the new `pwnmake` command.

* [SunshineCTF-2017-Public](https://github.com/SunshineCTF/SunshineCTF-2017-Public)
* [SunshineCTF-2018-Public](https://github.com/SunshineCTF/SunshineCTF-2018-Public)
* [SunshineCTF-2019-Public](https://github.com/SunshineCTF/SunshineCTF-2019-Public)
* [SunshineCTF-2020-Public](https://github.com/SunshineCTF/SunshineCTF-2020-Public)
* [SunshineCTF-2021-Public](https://github.com/SunshineCTF/SunshineCTF-2021-Public)
