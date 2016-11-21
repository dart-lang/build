# [![Build Status](https://travis-ci.org/dart-lang/build.svg?branch=master)](https://travis-ci.org/dart-lang/build) [![Coverage Status](https://coveralls.io/repos/dart-lang/build/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/build)

# Build Barback

Allows wrapping up a `Builder` as a `Transformer` so that it can be run in `pub`
or vice-versa.

## Using a Builder from Pub

Wrap the `Builder` instance with `new BuilderTransformer(builder)` and use it
like any other Transformer. The Builder used this way must follow the rules of
other Transformers, it cannot use inputs from outside the package where the
Transformer is specified in pubspec.yaml

## Using a Transformer with ahead of time codegen

Wrap the `Transformer` instance with `new TransformerBuilder(transformer)` and
run as any other `Builder`. The Transformer instance used this way must follow
the rules of other Builders, it cannot overwrite files it uses as inputs.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/build/issues
