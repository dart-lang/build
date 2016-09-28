import 'package:meta/meta.dart';

/// Extend or mixin this class to mark the implementation as a [Mock].
///
/// A mocked class implements all fields and methods with a default
/// implementation that does not throw a [NoSuchMethodError], and may be further
/// customized at runtime to define how it may behave using [when] or [given].
///
/// __Example use__:
///   // Real class.
///   class Cat {
///     String getSound() => 'Meow';
///   }
///
///   // Mock class.
///   class MockCat extends Mock implements Cat {}
///
///   void main() {
///     // Create a new mocked Cat at runtime.
///     var cat = new MockCat();
///
///     // When 'getSound' is called, return 'Woof'
///     when(cat.getSound()).thenReturn('Woof');
///
///     // Try making a Cat sound...
///     print(cat.getSound()); // Prints 'Woof'
///   }
///
/// **WARNING**: [Mock] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Mock] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js/ddc) and Dart for Mobile
/// (flutter).
class Mock {
  @override
  @visibleForTesting
  noSuchMethod(Invocation inv) {
    // noSuchMethod is that 'magic' that allows us to ignore implementing fields
    // and methods and instead define them later at compile-time per instance.
    // See "Emulating Functions and Interactions" on dartlang.org: goo.gl/r3IQUH
  }
}
