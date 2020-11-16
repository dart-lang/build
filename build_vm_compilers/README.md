<p align="center">
  Vm compilers for users of <a href="https://pub.dev/packages/build"><code>package:build</code></a>.
  <br>
  <a href="https://travis-ci.org/dart-lang/build">
    <img src="https://travis-ci.org/dart-lang/build.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://github.com/dart-lang/build/labels/package%3A%20build_vm_compilers">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3A%20build_vm_compilers.svg" alt="Issues related to build_vm_compilers" />
  </a>
  <a href="https://pub.dev/packages/build_vm_compilers">
    <img src="https://img.shields.io/pub/v/build_vm_compilers.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dev/documentation/build_vm_compilers/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Manual Usage](#manual-usage)

## Installation

This package is intended to be used as a [development dependency][] for users
of [`package:build`][] who want to run code in the Dart vm with precompiled
kernel files. This allows you to share compilation of dependencies between
multiple entrypoints, instead of doing a monolithic compile of each entrypoint
like the Dart VM would normally do on each run.

**Note**: If you want to use this package for running tests with
`pub run build_runner test` you will also need a `build_test` dev dependency.

## Usage

This package creates a `.vm.app.dill` file corresponding to each `.dart` file
that contains a `main` function.

These files can be passed directly to the vm, instead of the dart script, and
the vm will skip its initial parse and compile step.

You can find the output either by using the `-o <dir>` option for build_runner,
or by finding it in the generated cache directory, which is located at
`.dart_tool/build/generated/<your-package>`.

## Configuration

There are no configuration options available at this time.

## Custom Build Script Integration

If you are using a custom build script, you will need to add the following
builder applications to what you already have, sometime after the
`build_modules` builder applications:

```dart
    apply('build_vm_compilers|entrypoint',
        [vmKernelEntrypointBuilder], toRoot(),
        hideOutput: true,
        // These globs should match your entrypoints only.
        defaultGenerateFor: const InputSet(
            include: const ['bin/**', 'tool/**', 'test/**.vm_test.dart'])),
]
```

[development dependency]: https://dart.dev/tools/pub/dependencies#dev-dependencies
[`package:build`]: https://pub.dev/packages/build
