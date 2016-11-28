# [![Build Status](https://travis-ci.org/dart-lang/build.svg?branch=master)](https://travis-ci.org/dart-lang/build) [![Coverage Status](https://coveralls.io/repos/dart-lang/build/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/build)

These packages provide utilities for generating Dart code.

## `build`

Defines the interfaces for creating a `Builder` which is a way of doing codegen
that is compatible across build systems (pub, bazel, standalone runner).

For packages doing code generation this should generally be the only package
against which there is a public dependency. Packages may have a dev_depenency on
one or more of the other packages.

In particular, transformers should only be exposed via a separate package, which
has a dependency on `build_barback`. This allows core packages to not leak the
dependency on barback and all of its transitive deps to all consumers.

## `build_barback`

Allows wrapping up a `Builder` as a `Transformer` so that it can be run in `pub`
or vice-versa.

## `build_runner`

Provides `build` and `watch` utilities to enact builds.

This package should generally be a dev_dependency as it is used to run
standalone builds. The only exception would be wrapping the `build` and `watch`
methods with some other package.

## `build_test`

Stub implementations for classes in `Build` and some utilities for running
instances of builds and checking their outputs.

This package generally only be a dev_dependency as it introduces a dependency on
package:test. The exception to that would be if you were creating another
testing-only package that wraps this one.
