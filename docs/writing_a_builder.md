# Output Restrictions

A `Builder` must have outputs that are known statically based on input paths and
file extensions. For example an input named `foo.dart` always results in an
output named `foo.something.dart`. Builders are not allowed to read the input in
order to determine outputs. The only outputs that can be produced are those
which share a file base name with an input.

Having a predictable set of outputs allows:

-   Ability to reason about builds. We've found that arbitrarily complex builds
    tend to become difficult to debug.
-   Compatibility with a wide set of build systems. A Builder that follows these
    restrictions can run within `build_runner`, or in a build system like
    [bazel](https://bazel.build).

## Configuring outputs

Each `Builder` implements a property `buildExtensions` which is a `Map<String,
List<String>>` to configure what outputs are created for 1 or more input
extensions. For example with the configuration `{'.dart': ['.foo.dart']}` all
Dart files in the build will be passed as a primary input, and each build step
may produce a single asset. For the primary input `some_library.dart` the
allowed output is `some_library.foo.dart`. Only assets which will produce at
least one output will trigger a build step.

If a `Builder` has an empty string key in `buildExtensions` then every input
will trigger a build step, and the expected output will have the extension
appended. For example with the configuration `{'': ['.foo', '.bar']}` all files
will be passed as a primary input, and each build step may produce two assets.
For the primary input `some_file.txt` the allowed outputs are
`some_file.txt.foo` and `some_file.txt.bar`.

Keys in `buildExtensions` match a suffix in the path of potential inputs. That
is, a builder will run when an input ends with its input extension.
Valid outputs are formed by replacing the matched suffix with values in that 
map. For instance, `{'.dart': ['.g.dart']}` matches all files ending with
`.dart` and allows the builder to write a file  with the same name but with a
`.g.dart` extension instead.

Builders can declare more complex inputs and outputs by using a capture group
in their build input. Capture groups allow builders to move files across
directories. For instance, consider a builder that generates Dart code for
[Protocol Buffers][protobuf]. Let's assume that proto definitions are stored in
a top-level `proto/` folder, and that generated files should go to
`lib/src/proto/`. This cannot be expressed with simple build extensions that
may replace a suffix in the asset's path only.
Using `{'proto/{{}}.proto': ['lib/src/proto/{{}}.dart']}` as a build extension
lets the builder read files in `proto/` and emit Dart files in the desired 
location. Here, the __`{{}}`__ is called a _capture group_. Capture groups have
the following noteworthy properties:

- Capture groups match at least one character in the input path, but may match
  arbitrarily many characters.
- When the input uses a capture group, every output must reference that capture
  group as well.
- It is not currently allowed to declare multiple capture groups in one input
  extension.
- Capture groups match as many characters as possible. In the proto example,
  the asset `proto/nested/proto/test.proto` would match with `{{}}` capturing
  `nested/proto/test`. The shorter suffix match with `{{}}` capturing just
  `test` is not considered.
- General rules about build extensions matching suffixes still apply. When
  using capture groups, the suffix typically spans across multiple path
  components which is what enables directory moves.
  In the proto example, the input extension might match an entire file
  `proto/services/auth.proto`. With `{{}}` bound to `services/auth`, the
  expected output is `lib/src/proto/services/auth.dart`.
- Build extensions using capture groups can start with `^` to enforce matches
  over the entire input (which is still technically a suffix).
  In the example above, the builder would also run on 
  `lib/src/proto/test.proto` (outputting `lib/src/lib/src/proto/test.dart`).
  If the builder had used `^proto/{{}}.proto` as an input, it would not have
  run on strict suffix matches.

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
inputs existing Dart files in `lib/`. - Write an empty file to
`lib/foo.placeholder` - Use the extension config `{'.placeholder': ['.dart']}` -
Ignore the `buildStep.inputId` and find the real inputs with
`buildStep.findAssets(new Glob('lib/*dart')`

[protobuf]: https://developers.google.com/protocol-buffers