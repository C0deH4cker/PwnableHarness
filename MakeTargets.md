# PwnableHarness: C/C++ build and Docker management system for CTF challenges

  The new, preferred way to run PwnableHarness targets is with `pwnmake`. This
  invocation runs all build and Docker management commands in a Docker container
  for increased portability and easier workspace configuration. You can also
  still use `make` from the PwnableHarness directory if you prefer.

## Command line reference

  Project-specific targets like `docker-build[project]` can also be used without
  an argument. When no argument is provided, it will run that target for all
  projects. So `docker-build` will build the Docker images for ALL projects.
  Note that descendent projects are included automatically. If you only want
  to run the target in the project but not its descendents, append "-one" to
  the target name (`docker-build[project]` becomes `docker-build-one[project]`).

### Target descriptions:

* `build[project]`:
         Compile and link all defined TARGETS for the given project.
         This is the default target, so running `pwnmake` without any provided
         target is the same as running `pwnmake build`.
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
         directory in your workspace. Just ensure that the http server has read
         access to the contents.
* `deploy[project]`:
         Without an argument, this is shorthand for `docker-start publish`.
         Projects can optionally define the `DEPLOY_COMMAND` variable in their
         `Build.mk` file, which is a command to be run from the project's
         directory when running `deploy` or `deploy[project]`.
* `docker-build[project]`:
         Build the project's Docker image, ensuring all dependencies are up to
         date. For example, editing a C file and then running the `docker-build`
         target will recompile the binary and rebuild the Docker image.
* `docker-rebuild[project]`:
         Force rebuild the project's Docker image, even if all of its
         dependencies are up to date.
* `docker-start[project]`:
         Create and start the project's Docker container, ensuring the Docker
         image it is based on is up to date.
* `docker-restart[project]`:
         Restart the project's Docker container.
* `docker-stop[project]`:
         Stop the project's Docker container.
* `docker-clean[project]`:
         Stop the project's Docker container, and delete its image and any
         workdir volumes.
* `list`:
         Display a list of all discovered project directories.
* `list-targets`:
         Display a list of all provided targets.

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
