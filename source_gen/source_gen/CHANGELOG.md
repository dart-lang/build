##0.4.0+1

* Support the latest release of `analyzer` and `args`.

##0.4.0

* Analysis no longer parses function bodies. This greatly speeds up generation,
  but it could break any usage that needs function bodies.

##0.3.0+2

* Fixed `README.md`.

##0.3.0+1

* Updates for move to `dart-lang` org on GitHub.

##0.3.0

* **BREAKING** Returning a descriptive value from `generate`.

* **BREAKING** Fixed incorrectly named argument `omitGenerateTimestamp`.

* `JsonSerializable`: Handle `dynamic` and `var` as field types.

##0.2.4

* Added `associatedFileSet` to `Generator`. Allows a generator to specify
  that changes to any file in a directory next to a Dart source file can
  initiate a generation run.

##0.2.3

* Use `async *`. Requires SDK >= `1.9.0-dev.10`

* Protect against crash during code format.

##0.2.2

* Added `omitGenerateTimestamp` (incorrectly spelled) named argument to 
  `generate` method.

* `Generator.generate` is now called with the `LibraryElement`, too.

##0.2.1

* Fixed critical bug affecting annotation matching.
  [#35](https://github.com/dart-lang/source_gen/issues/35)
  
* Started using published `dart_style` package.

##0.2.0+2

* Tweaks to `JsonGenerator` to address 
  [#31](https://github.com/dart-lang/source_gen/issues/31) and
  [#32](https://github.com/dart-lang/source_gen/issues/32)

##0.2.0+1
* Updated `README.md` with new examples.
* Fixed sub-bullet indenting in `CHANGELOG.md`.

##0.2.0
* **BREAKING** Moved and renamed JSON serialization classes.
* Added a `JsonLiteral` generator.
* Improved handling and reporting of Generator errors.
* `JsonGenerator`
    * Learned how to use constructor arguments.
    * Learned how to properly handle `DateTime`.

##0.1.1
* Support for parametrized annotations.
* Add named arguments to `JsonGenerator`.

##0.1.0+1
* `README.md` updates.

##0.1.0
* **BREAKING** `Generator.generate` is now async – returns `Future<String>`
* Big update to `README.md`.

##0.0.1
* Ready for experimentation.

##0.0.0+1
* First play release.
