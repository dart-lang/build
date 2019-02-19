[![Build Status](https://travis-ci.org/dart-lang/build.svg?branch=master)](https://travis-ci.org/dart-lang/build)
[![Build Status](https://ci.appveyor.com/api/projects/status/wga4jexvmjih346p?svg=true)](https://ci.appveyor.com/project/kevmoo/build)

These packages provide libraries for generating, compiling and serving Dart code.

[Getting started with build_runner](https://github.com/dart-lang/build/blob/master/docs/getting_started.md)

[Integrating with Travis](https://github.com/dart-lang/build/blob/master/docs/travis.md)

[General FAQ](https://github.com/dart-lang/build/blob/master/docs/faq.md)

[Windows FAQ](https://github.com/dart-lang/build/blob/master/docs/windows_faq.md)

[FAQ for Builder authors](https://github.com/dart-lang/build/blob/master/docs/builder_author_faq.md).

[Additional Docs](https://github.com/dart-lang/build/blob/master/docs/)

## [build](https://github.com/dart-lang/build/blob/master/build/README.md)

Defines the interfaces for creating a `Builder` which is a way of doing codegen
that is compatible across build systems (pub, bazel, standalone runner).

For packages doing code generation this should generally be the only package
against which there is a public dependency. Packages may have a dev_dependency on
one or more of the other packages.

## [build_config](https://github.com/dart-lang/build/blob/master/build_config/README.md)

Support for parsing `build.yaml` files. Used by `build_runner`.

## [build_modules](https://github.com/dart-lang/build/blob/master/build_modules/README.md)

Support for discovering the sub-modules within packages and creating summaries
of those modules. Used by `build_web_compilers` but should not be used directly
by most users.

## [build_resolvers](https://github.com/dart-lang/build/blob/master/build_resolvers/README.md)

An implementation of the `Resolver` interface to use the analyzer during build
steps.

## [build_runner](https://github.com/dart-lang/build/blob/master/build_runner/README.md)

Provides utilities to enact builds and a way to automatically run builds based
on configuration.

This package should generally be a dev_dependency as it is used to run
standalone builds. The only exception would be wrapping the `build` and `watch`
methods with some other package.

## [build_test](https://github.com/dart-lang/build/blob/master/build_test/README.md)

Stub implementations for classes in `Build` and some utilities for running
instances of builds and checking their outputs.

This package generally only be a dev_dependency as it introduces a dependency on
package:test. The exception to that would be if you were creating another
testing-only package that wraps this one.

## [build_web_compilers](https://github.com/dart-lang/build/blob/master/build_web_compilers/README.md)

Provides the `dart2js` and `dartdevc` support for your package. To use this
package you should add it as a dev_dependency.

If you are using the automated build scripts, your project will automatically
start being compiled with dartdevc, and you can start developing with chrome
without any configuration.

<!--
TODO: scratch_space
-->

## Examples

The [example](https://github.com/dart-lang/build/tree/master/example)
directory has an example of a build with custom builders which generate outputs
into both the source tree and a hidden generated directory. Try a build with
`pub run build_runner build -o web:deploy` to see what the output looks like.

Most projects should not need custom builders. A more typical project which uses
Angular and compiles to javascript can be found in the [angular repo][hacker_news].

[hacker_news]:https://github.com/dart-lang/angular/tree/master/examples/hacker_news_pwa
