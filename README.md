# [![Build Status](https://travis-ci.org/dart-lang/build.svg?branch=master)](https://travis-ci.org/dart-lang/build) [![Coverage Status](https://coveralls.io/repos/dart-lang/build/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/build)

These packages provide utilities for generating Dart code.

## `build`

Defines the basic pieces of how a build happens and how they interact.

## `build_runner`

Provides `build` and `watch` utilities to enact builds.

## `build_barback`

Allows wrapping up a `Builder` as a `Transformer` so that it can be run in `pub`
or vice-versa.

## `build_test`

Stub implementations for classes in `Build` and some utilities for running
instances of builds and checking their outputs.
