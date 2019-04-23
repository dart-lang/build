<p align="center">
  Module builders for modular compilation pipelines.
  <br>
  <a href="https://travis-ci.org/dart-lang/build">
    <img src="https://travis-ci.org/dart-lang/build.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://github.com/dart-lang/build/labels/package%3A%20build_modules">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3A%20build_modules.svg" alt="Issues related to build_modules" />
  </a>
  <a href="https://pub.dartlang.org/packages/build_modules">
    <img src="https://img.shields.io/pub/v/build_modules.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dartlang.org/documentation/build_modules/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

This package provides generic module builders which can be used to create
custom compilation pipelines. It is used by [`build_web_compilers`][] and
[`build_vm_compilers`][] package which provides standard builders for the web
and vm platforms.

## Usage

There should be no need to import this package directly unless you are developing
a custom builder for web. See documentation in [`build_web_compilers`][] and
[`build_vm_compilers`][] for more details on building your Dart code.

[`build_web_compilers`]: https://pub.dartlang.org/packages/build_web_compilers
[`build_vm_compilers`]: https://pub.dartlang.org/packages/build_vm_compilers
