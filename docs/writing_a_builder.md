# Output Restrictions

A `Builder` must have outputs that are known statically based on input paths and
file extensions. For example an input named `foo.dart` always results in an
output named `foo.something.dart`. Builders are not allowed to read the input in
order to determine outputs. The only outputs that can be produced are those
which share a file base name with an input.

Having a predictable set of outputs allows:

- Ability to reason about builds. We've found that arbitrarily complex builds
  tend to become difficult to debug.
- Compatibility with a wide set of build systems. A Builder that follows these
  restrictions can run within `build_runner`, or in a build system like
  [bazel](https://bazel.build).

## Configuring outputs

Each `Builder` implements a property `buildExtensions` which is a
`Map<String, List<String>>` to configure what outputs are created for 1 or more
input extensions. For example with the configuration `{'.dart': ['.foo.dart']}`
all Dart files in the build will be passed as a primary input, and each build
step may produce a single asset. For the primary input `some_library.dart` the
allowed output is `some_library.foo.dart`. Only assets which will produce at
least one output will trigger a build step.

If a `Builder` has an empty string key in `buildExtensions` then every input
will trigger a build step, and the expected output will have the extension
appended. For example with the configuration `{'': ['.foo', '.bar']}` all files
will be passed as a primary input, and each build step may produce two assets.
For the primary input `some_file.txt` the allowed outputs are
`some_file.txt.foo` and `some_file.txt.bar`.

## Working around the restrictions

### Builders which produce an unknown number of outputs

Often codegen is used to build Dart code - in these cases we can usually
generate all of the code in a single file. Dart does not have restrictions like
Java does - we don't need a 1:1 mapping between files and classes.

If it's not possible to generate the output into a set of files known ahead of
time it's possible to write them to a single archive.

### Builders which are based on an unknown number of inputs

In Barback it was possible to write an `AggregateTransformer`, but there is no
matching concept as `Builder` - outputs must be known statically and must share
a `basename` with their input.

In most cases the expected file is known statically, so the package can have a
placeholder (with a different extension) where that file should be created. For
example: if a Builder is meant to produce the file `lib/foo.dart` and use as
inputs existing Dart files in `lib/`.
- Write an empty file to `lib/foo.placeholder`
- Use the extension config `{'.placeholder': ['.dart']}`
- Ignore the `buildStep.inputId` and find the real inputs with
  `buildStep.findAssets(new Glob('lib/*dart')`
