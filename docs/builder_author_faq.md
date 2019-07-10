## When should a Builder build to `cache` vs `source`?

Outputs to `source` will generally be published with the package on pub. **This
can be risky.** If the generated code depends on _any_ details from the current
pub solve - that is it reads information from dependencies - then a consumer of
the package which has different versions of dependencies in their pub solve
**may be broken**. If the generated code imports any libraries, including from
the package providing the builder, it must only use the API surface area which
is guaranteed to not break without a major version bump.

Outputs to `cache` will never be published with the package, and if they are
required to compile or run, then the build system must be used by every consumer
of the code. **This is always safe**, but may place limitations on the end user.
Any outputs which are used _during_ a build to produce other outputs, but don't
need to be compiled or seen by the user, should also be built to `cache`.

## How can I have temporary outputs only used during the Build?

Due to build restrictions - namely that a builder can't read the outputs
produced by other builders in the same phase - it's sometimes necessary to write
information to a temporary file in one phase, then read that in a subsequent
phase, but the intermediate result is not a useful output outside of the build.

Use a `PostProcessBuilder` to "delete" files so they are not included in the
merged output directory or available through the development server. Note that
files are never deleted from disk, instead a "delete" by a `PostProcessBuilder`
acts a filter on what assets can be seen in the result of the build. This works
best if temporary assets have a unique extension.

The `FileDeletingBuilder` from the `build` package is designed for this case and
only needs to be configured with the extensions it should remove. In some cases
the builder should only operate in release mode so the files can see be seen in
development mode - use the `isEnabled` argument to the constructor rather than
returning a different builder or passing a different set of extensions - if the
extensions change between modes it will invalidate the entire build.

For example:

```dart
// In lib/builder.dart
PostProcessBuilder temporaryFileCleanup(BuilderOptions options) =>
    const FileDeletingBuilder(const ['.used_during_build'],
        isEnabled: options.config['enabled'] as bool ?? false);
Builder writesTemporary([_]) => ...
Builder readsTemporaryWritesPermanent([_]) => ...
```

```yaml
builders:
  my_builder:
    import: "package:my_package/builders.dart"
    builder_factories:
       - writesTemporary
       - readsTemporaryWritesPermanent
    build_extensions:
      .dart:
        - .used_during_build
        - .output_for_real
    auto_apply: dependents
    applies_builders:
      - my_package|temporary_file_cleanup
post_process_builders:
  temporary_file_cleanup:
    import: "package:my_package/builders.dart"
    builder_factory: temporaryFileCleanup
    defaults:
      release_options:
        enabled: true
```

## How can I debug my builder?

After running a build, or by running the `generate-build-script` command, a
build script will be written to `.dart_tool/build/entrypoint/build.dart`. This
is a Dart VM application that can be run manually, including with the
observatory enabled. See the [observatory docs][] or [IntelliJ debugging docs][]
for usage instructions. The build script takes the same arguments as `pub run
build_runner`, for example:

`dart --observe --pause-isolates-on-start .dart_tool/build/entrypoint/build.dart build`


[observatory docs]:https://dart-lang.github.io/observatory/get-started.html
[IntelliJ debugging docs]:https://www.jetbrains.com/help/idea/dart.html#dart_run_debug_command_line_application
