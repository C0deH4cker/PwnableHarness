# PwnableHarness: C/C++ build and Docker management system for CTF challenges

  The new, preferred way to run PwnableHarness targets is with `pwnmake`. This
  invocation runs all build and Docker management commands in a Docker container
  for increased portability and easier workspace configuration. You can also
  still use `make` from the PwnableHarness directory if you prefer.

## Command line reference

  Targets with arguments like `docker-build[image]` can also be used without an
  argument. When no argument is provided, it will run that target for all
  possible values of that parameter. So `docker-build` will build ALL Docker
  images in the workspace.

### Target descriptions:

* `all[project]`:
         Compile and link all defined TARGETS for the given project.
         This is the default target, so running `pwnmake` without any provided
         target is the same as running `pwnmake all`.
* `clean[project]`:
         Deletes all build products for the given project. Running this target
         without an argument is effectively the same as `rm -rf .build`. Note
         that individual projects can provide custom `clean` actions by using
         the `clean::` multi-recipe target.
* `publish[project]`:
         Copy all files that a project requests to be published to the `publish`
         directory at the top level of the workspace. Projects can define the
         `PUBLISH`, `PUBLISH_BUILD`, and `PUBLISH_TOP` variables in their
         `Build.mk` file to specify which files should be published. All files
         to be published are ensured to be up to date. So, if a project defines
         `PUBLISH_BUILD := $(TARGET)` and you run `publish` before building
         the executable, it will build that target and then copy it to the
         `publish` directory. Note that the `publish` directory mirrors your
         workspace's directory structure. So if you have `foo/bar/Build.mk`
         which publishes its target (named `baz`), that will be copied to
         `publish/foo/bar/baz`. For serving published files over HTTP(S), it is
         useful to create symlinks from `/var/www/<path>` into the `publish`
         directory in your workspace. Just ensure that the http server user has
         read access to the contents.
* `deploy[project]`:
         Without an argument, this is shorthand for `docker-start publish`.
         Projects can optionally define the `DEPLOY_COMMAND` variable in their
         `Build.mk` file, which is a command to be run from the project's
         directory when running `deploy` or `deploy[project]`.
* `docker-build[image]`:
         Build the named Docker image, ensuring all dependencies are up to date.
         For example, editing a C file and then running the `docker-build`
         target will recompile the binary and rebuild the Docker image.
* `docker-rebuild[image]`:
         Force rebuild a named Docker image, even if all of its dependencies are
         up to date.
* `docker-start[container]`:
         Create and start the named Docker container, ensuring the Docker image
         it is based on is up to date.
* `docker-restart[container]`:
         Restart the named Docker container.
* `docker-stop[container]`:
         Stop the named Docker container.
* `docker-clean[image]`:
         Stop any container running from this Docker image and delete it, then
         delete the Docker image. Also will delete the associated Docker volume
         for the workdir, if one exists. Running this without an argument will
         stop all containers and delete all images that are defined by any
         project in the workspace.
* `list`:
         Display a list of all discovered project directories.
* `list-targets`:
         Display a list of all provided targets.
* `base`:
         Build only the core PwnableHarness binaries.

### Command-line variables:

* `VERBOSE=1`:
         Echo each command as it executes instead of a concise description.
* `WITH_EXAMPLES=1`:
         Include the example projects in the workspace.
* `MKDEBUG=1`:
         Output additional debug information about the PwnableHarness project
         discovery logic in its Makefiles.

### Additional information:

 * To prevent a directory from being searched for `Build.mk` project files, you
   can rename it so it ends in `.disabled`. For example:

```sh
# Don't use Build.mk files under OldRepo
mv OldRepo OldRepo.disabled
# More concisely:
mv OldRepo{,.disabled}
```

 * You can create a `Config.mk` file in the top-level of your workspace (or any
   direct subdirectory) that will be included before all of the PwnableHarness
   Makefile code. This is mainly intended for defining variables prefixed with
   `CONFIG_*` or `DEFAULT_*`. Examples:

   - `CONFIG_IGNORE_32BIT`: Don't build 32-bit versions of PwnableHarness
   - `CONFIG_PUBLISH_LIBPWNABLEHARNESS`: Publish `libpwnableharness(32|64).so`
   - `DEFAULT_(BITS|OFLAGS|CFLAGS|CXXFLAGS|LDFLAGS|CC|CXX|LD|AR)`: Override the
     default value of each of these build variables for your workspace.

 * Any directory can contain an `After.mk` file, which is included during the
   project discovery phase after all subdirectories have been included. Project
   discovery is performed as a depth-first traversal. When visiting a directory,
   its `Build.mk` file will be included, then all of its subdirectories will be
   visited, and then its `After.mk` file will be included. Both `Build.mk` and
   `After.mk` are optional in each directory. `After.mk` is a good place for a
   parent/ancestor project to collect settings defined by its descendants.
