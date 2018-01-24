# Transforming code with `build` and `build_runner`

Unlike the [old `barback` and `pub`][pub] asset systems, it's not permitted to overwrite or otherwise transform existing on-disk files as part of the build process, and our newer build tools and packages will throw exceptions if this is attempted.

[pub]: https://www.dartlang.org/tools/pub/transformers

## Examples

<!-- TODO: Add more common examples. -->

### Class members

In Dart Classic and Pub, you might write something like the following:

```dart
class Calculator {
  @memoize
  int doExpensiveCalculation() => ...
}
```

... and writing a [pub transformer][pub] to understand `@memoize` and re-write the class:

```dart
class Calculator {
  // Code-generated field.
  int _memoize1;

  // New code-generated function.
  int doExpensiveCalculation() => _memoize1 ??= _doExpensiveCalculation();

  // Original user-authored function
  int _doExpensiveCalculation() => ...
}
```

As mentioned above, this is not permitted in the newer build systems.

You can _emulate_ this functionality using `part` files. For example, the following:

```dart
// this file = calculator.dart
part 'calculator.g.dart';

abstract class Calculator {
  // Redirect to a generated class.
  factory Calculator() = _$Calculator;

  @memoize
  int doExpensiveCalculation() => ...
}
```

And generate the following:

```dart
// this file = calculator.g.dart
part of 'calculator.dart';

abstract class _$Calculator extends Calculator {
  int _memoize1;

  @override
  int doExpensiveCalculation() => _memoize1 ??= super.doExpensiveCalculation();
}
```

To the _user_ of `Calculator`, the class works exactly the same:

```dart
main() {
  var calculator = new Calculator();
  print(calculator.doExpensiveCalculation());
  print(calculator.doExpensiveCalculation());
}
```

## FAQ

### But, why?

While it's _tempting_ to want to use code generation as a form of "macros" or implementing your own higher-order language features, it unfortunately makes most of the optimizations around consistent, fast, and incremental builds nearly impossible. It's possible that we could _emulate_ this in the future with either (a) new language features or (b) changes to our compilers, but this isn't something planned at this time.
