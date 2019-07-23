<p align="center">
  Module builders for modular compilation pipelines.
  <br>
  <a href="https://travis-ci.org/dart-lang/build">
    <img src="https://travis-ci.org/dart-lang/build.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://github.com/dart-lang/build/labels/package%3A%20build_modules">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3A%20build_modules.svg" alt="Issues related to build_modules" />
  </a>
  <a href="https://pub.dev/packages/build_modules">
    <img src="https://img.shields.io/pub/v/build_modules.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dev/documentation/build_modules/latest/">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

This package provides generic module builders which can be used to create custom
compilation pipelines. It is used by [`build_web_compilers`][] and
[`build_vm_compilers`][] package which provides standard builders for the web
and vm platforms.

## Usage

There should be no need to import this package directly unless you are
developing a custom compiler pipeline. See documentation in
[`build_web_compilers`][] and [`build_vm_compilers`][] for more details on
building your Dart code.

[`build_web_compilers`]: https://pub.dev/packages/build_web_compilers
[`build_vm_compilers`]: https://pub.dev/packages/build_vm_compilers

## Module creation

The overall process for emitting modules follows these steps:

1. Emit a `.module.library` asset for every `.dart` library containing a
   description of the directives (imports, exports, and parts), a list of the
   `dart:` imports used, and a determination of whether the library is an
   "entrypoint". Entrypoint libraries are either those which are likely to be
   directly imported (they are under `lib/` but not `lib/src/`) or which have a
   `main`. Only the libraries that can be imported (they aren't part files) will
   have an output. This step is mainly separated out for better invalidation
   behavior since the output will change less frequently than the code. The
   outputs from this step are non differentiated by platform.
2. Emit package level `.meta_module` assets. This is an aggregation of the
   `.module.library` information with a first run at creating a module
   structure. The output depends on the algorithm, described below. The outputs
   from this step are specific to a platform and will indicate which libraries
   contain unsupported `dart:` imports for a platform. Conditional imports will
   also be resolved to a concrete dependency based on the platform. In this step
   the dependencies of modules references the imported library, which may not
   match the primary source of the module containing that library.
3. Emit package level `.meta_module.clean` assets. This step performs an extra
   run of the strongly connected components algorithm so that any libraries
   which are in an import cycle are grouped into a single module. This is done
   as a separate step so that it can be sure it may read all the `.meta_module`
   results across packages in a dependency cycle so that it may resolve import
   cycles across packages. As modules are merged due to import cycles the new
   module becomes the union of their sources and dependencies. Dependencies are
   resolved to the "primary source" of the module containing the imported
   library.
4. Emit `.module` assets which contain a filtered view of the package level
   meta-module specific to a single module. These are emitted for the "primary
   source" of each module, as well as each library which is an entrypoint.

## Module algorithms

### Fine

The fine-grained module algorithm is straightforward - any dart library which
_can_ be it's own module, _is_ it's own module. Libraries are only grouped into
a module when there is an import cycle between them.

The `.meta_module` step filters unsupported libraries and does no clustering.
Import cycles are resolved by the `.meta_module.clean` step.

### Coarse

The coarse-grained module algorithm attempts to cluster libraries into larger
modules without bringing in more code than may be imported by downstream code.
It assumes that libraries under `lib/src/` won't be imported directly outside of
the package. Assuming that external packages only import the libraries outside
of `lib/src/` then no code outside of the transitive imports will be brought in
due to module clustering.

The `.meta_module` step performs strongly connected components and libraries
which are in an import cycle are grouped into modules since they can't be
ordered otherwise. Within each top level directory under the package (`lib/`,
`test/`, etc) the libraries are further bundled into modules where possible.
Each "entrypoint" library is always kept in it's own modules (other than in the
case of import cycles). Non entrypoint libraries are grouped where possible
based on the entrypoints that transitively import them. Any non-entrypoint which
is only transitively imported by a single entrypoint is merged into the module
for that entrypoint. Any non-entrypoints which are imported by the same set of
entrypoints are merged into their own module. The "primary source" for any
module is always the lowest alpha-sorted source, regardless of whether it is an
entrypoint. As libraries are merged the module becomes the union of their
sources and dependencies.
