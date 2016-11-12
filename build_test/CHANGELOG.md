## 0.2.0+1

- Support `pkg/build` v0.5.0

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
