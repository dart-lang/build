## 0.3.0

- **BREAKING** removed testPhases utility. Tests should be using testBuilder
- Drop dependency on build_runner package

## 0.2.1

- Support the package split into build/build_runner/build_barback
- Expose additional test utilities that used to be internal to build

## 0.2.0

- Upgrade build package to 0.4.0
- Delete now unnecessary `GenericBuilderTransformer` and use
  `BuilderTransformer` in the tests.

## 0.1.2

- Add `logLevel` and `onLog` named args to `testPhases`. These can be used
  to test your log messages, see `test/utils_test.dart` for an example.

## 0.1.1

- Allow String or Matcher for expected output values in `testPhases`.

## 0.1.0

- Initial version, exposes many basic utilities for testing `Builder`s using in
  memory data structures. Most notably, the `testPhases` method.
