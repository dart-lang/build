## 0.5.1+2

* Avoid calling `computeNode()` while instantiating annotation values

## 0.5.1+1

* Support the latest version of `build` package.

## 0.5.1

* Added GeneratorBuilder option isStandalone to generate files that aren't 
  part of source file.

## 0.5.0+3

* Fixed multi-line error output.

## 0.5.0+2

* Remove an outdated work-around.

* Make strong-mode clean.

## 0.5.0+1

* Support the latest version of `pkg/build`.

## 0.5.0

* **Breaking**: Switch to the `build` package for running `Generator`s. This
  means that the top level `build` and `generate` functions are no longer
  available, and have been replaced by the top level `build`, `watch`, and
  `serve` functions from the `build` package, and the `GeneratorBuilder` class.
  See `tool/build.dart`, `tool/watch.dart`, and `tool/phases.dart` for usage.

  * Note that the `build` package is experimental, and likely to change.

* **Breaking**: The build package provides an abstraction for reading/writing
  files via the `BuildStep` class, and that is now also provided to
  `Generator#generate` and `GeneratorForAnnotation#generateForAnnotatedElement`
  as a second argument.
  
* Timestamps are no longer included in generated code.

* There is no longer a need to specify the files related to an individual
  generator via `AssociatedFileSet`. Simply use the `BuildStep` instance to read
  and write files and the `build` package will track any files you read in and
  run incremental rebuilds as necessary.

## 0.4.8

* Added support for `Symbol` and `Type` in annotations.

* Improved error output when unable to create an instance from an annotation.

## 0.4.7+2

* Upgrade to `analyzer '^0.27.1'` and removed a work-around for a fixed 
  `analyzer` issue.

## 0.4.7+1

* Upgrade to `analyzer '^0.27.0'`.

## 0.4.7

* `JsonSerializableGenerator` now supports classes with read-only properties.

## 0.4.6

* `JsonSerializable`: Added `JsonKey` annotation.

* Improved output of generation errors and stack traces.

* Require `analyzer '^0.26.2'`.

## 0.4.5+1

* Handle `null` values for `List` properties.

## 0.4.5

* `JsonSerializable`: add support for `List` values.

## 0.4.4+1

* Updated `README.md` to highlight the `build_system` package and de-emphasize
  Dart Editor.

## 0.4.4

* Added `omitGenerateTimestamp` and `followLinks` named args to `build`.

* Added `followLinks` to `generate`.

## 0.4.3+1

* Update tests to use a more reliable method to find the current package root.

## 0.4.3

* Require Dart `1.12`.

* Add implicit support for `.packages`. If the file exists, it is used.
  If not, we fall back to using the `packages` directory.

* Support the latest releases of `analyzer` and `dart_style` packages.

## 0.4.2

* Use `fromJson` if it's defined in a child field.

## 0.4.1

* Match annotations defined in parts. *Thanks, [Greg](https://github.com/greglittlefield-wf)!*

## 0.4.0+1

* Support the latest release of `analyzer` and `args`.

## 0.4.0

* Analysis no longer parses function bodies. This greatly speeds up generation,
  but it could break any usage that needs function bodies.

## 0.3.0+2

* Fixed `README.md`.

## 0.3.0+1

* Updates for move to `dart-lang` org on GitHub.

## 0.3.0

* **BREAKING** Returning a descriptive value from `generate`.

* **BREAKING** Fixed incorrectly named argument `omitGenerateTimestamp`.

* `JsonSerializable`: Handle `dynamic` and `var` as field types.

## 0.2.4

* Added `associatedFileSet` to `Generator`. Allows a generator to specify
  that changes to any file in a directory next to a Dart source file can
  initiate a generation run.

## 0.2.3

* Use `async *`. Requires SDK >= `1.9.0-dev.10`

* Protect against crash during code format.

## 0.2.2

* Added `omitGenerateTimestamp` (incorrectly spelled) named argument to
  `generate` method.

* `Generator.generate` is now called with the `LibraryElement`, too.

## 0.2.1

* Fixed critical bug affecting annotation matching.
  [#35](https://github.com/dart-lang/source_gen/issues/35)

* Started using published `dart_style` package.

## 0.2.0+2

* Tweaks to `JsonGenerator` to address
  [#31](https://github.com/dart-lang/source_gen/issues/31) and
  [#32](https://github.com/dart-lang/source_gen/issues/32)

## 0.2.0+1
* Updated `README.md` with new examples.
* Fixed sub-bullet indenting in `CHANGELOG.md`.

## 0.2.0
* **BREAKING** Moved and renamed JSON serialization classes.
* Added a `JsonLiteral` generator.
* Improved handling and reporting of Generator errors.
* `JsonGenerator`
    * Learned how to use constructor arguments.
    * Learned how to properly handle `DateTime`.

## 0.1.1
* Support for parametrized annotations.
* Add named arguments to `JsonGenerator`.

## 0.1.0+1
* `README.md` updates.

## 0.1.0
* **BREAKING** `Generator.generate` is now async – returns `Future<String>`
* Big update to `README.md`.

## 0.0.1
* Ready for experimentation.

## 0.0.0+1
* First play release.
