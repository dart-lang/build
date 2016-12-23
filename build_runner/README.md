# [![Build Status](https://travis-ci.org/dart-lang/build.svg?branch=master)](https://travis-ci.org/dart-lang/build) [![Coverage Status](https://coveralls.io/repos/dart-lang/build/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/build)

# `build_runner`

This package provides a concrete way of generating files using Dart code,
outside of `pub`. These files are generated directly on disk in the current
package folder, and rebuilds are _incremental_.

## Running Builds

In order to run a build, you write a script which uses one of the three top
level functions defined by this library:

- **build**: Runs a single build and exits.
- **watch**: Continuously runs builds as you edit files.
- **serve**: Same as `watch`, but also provides a basic file server which blocks
    if there are ongoing builds.

All three of these methods have a single required argument, a `PhaseGroup`. This
is conceptually just a `List<Phase>` with some helper methods. Each of these
`Phase`s runs sequentially, and blocks until the previous `Phase` is completed.

A single `Phase` may be composed of one or more `BuildAction`s, which are just
a combination of a single `Builder` and a single `InputSet`. The `Builder` is
what will actually generate outputs, and the `InputSet` determines what the
primary inputs to that `Builder` will be. All `BuildAction`s in a `Phase` can
be ran at the same time, and cannot read in the outputs of any other
`BuildAction` in the same `Phase`.

Lets look at a very simple example, with a single `BuildAction`. You can ignore
the `CopyBuilder` for now, just know that its a `Builder` which copies files:

```dart
import 'package:build_runner/build_runner.dart';

main() async {
  /// The [PhaseGroup#singleAction] constructor is a shorthand for:
  ///
  ///   new PhaseGroup().newPhase().addAction(builder, inputSet);
  await build(new PhaseGroup.singleAction(
      new CopyBuilder('.copy'), new InputSet('my_package', ['lib/*.dart'])));
}
```

The above example would copy all `*.dart` files directly under `lib` to
corresponding `*.dart.copy` files. Each time you run a build, it will check for
any changes to the input files, and rerun the `CopyBuilder` only for the inputs
that actually changed.

You can add as many actions as you want to the first phase using the `addAction`
method, and they will all run at the same time. For example, you could make
multiple copies:

```dart
main() async {
  var inputs = new InputSet('my_package', ['lib/*.dart']);
  await build(new PhaseGroup().newPhase()
      ..addAction(new CopyBuilder('.copy1'), inputs)
      ..addAction(new CopyBuilder('.copy2'), inputs));
}
```

Lets say however, that you want to make a copy of one of your copies. Since
no action can read outputs of another action in the same phase, you need to add
an additional `Phase`:

```dart
main() async {
  var phases = new PhaseGroup();
  group.newPhase().addAction(
      new CopyBuilder('.copy'), new InputSet('my_package', ['lib/*.dart']));
  group.newPhase().addAction(
      new CopyBuilder('.bak'), new InputSet('my_package', ['lib/*.dart.copy']));

  await build(phases);
}
```

This time, all the `*.dart.copy` files will be created first, and then the next
`Phase` will read those in and create additional `*.dart.copy.bak` files. You
can add as many phases as you want, but in general it's better to add more
actions to a single phase since they can run at the same time.

**Note**: Any time you change your build script (or any of its dependencies),
the next build will be a full rebuild. This is because the system has no way
of knowing how that change may have affected the outputs.

### Inputs

Valid inputs follow the general dart package rules. You can read any files under
the top level `lib` folder any package dependency, and you can read all files
from the current package.

In general it is best to be as specific as possible with your `InputSet`s,
because all matching files will be provided to `declareOutputs`.

### Outputs

You may only output files in the current package, but anywhere in the current
package is allowed.

You are not allowed to overwrite existing files, only create new ones.

Outputs from previous builds will not be treated as inputs to later ones.

### Source control

This package creates a top level `.dart_tool` folder in your package, which
should not be submitted to your source control repo (likely this just means
adding '.dart_tool' to your '.gitignore' file).

When it comes to generated files it is generally best to not submit them to
source control, but a specific `Builder` may provide a recommendation otherwise.

It should be noted that if you do submit generated files to your repo then when
you change branches or merge in changes you may get a warning on your next build
about declared outputs that already exist. This will be followed up with a
prompt to delete those files. You can type `l` to list the files, and then type
`y` to delete them if everything looks correct. If you think something is wrong
you can type `n` to abandon the build without taking any action.

### Publishing packages

In general generated files should be published with your package, but this may
not always be the case. Some `Builder`s may provide a recommendation for this as
well.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/build/issues
