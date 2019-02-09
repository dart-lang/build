## When should a Builder build to `cache` vs `source`?

Use `build_to: source` when:
- The generated code should be `pub publish`ed with the package and used by
  downstream packages without running a build themselves.
- The generated code _does not_ depend on details outside of the containing
  package that might change with a different version of its dependencies. Any
  details from the _generating_ package, or any other dependency used by the
  generated code must not change without a major version bump.

Use `build_to: cache` when:
- The builder targets use cases for "application" packages that are unlikely to
  be published rather than packages which will be published and become
  dependencies.
- The generated code uses details from outside of the package with the generated
  code, including from the _generating_ package which may change without a major
  version bump.
- The builder generates lots of files that the user might not expect to see.

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
observatory enabled. See the [observatory docs][] for usage instructions.

[observatory docs]:https://dart-lang.github.io/observatory/get-started.html
