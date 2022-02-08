// Copyright 2019 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// An annotation to direct Mockito to generate mock classes.
///
/// During [code generation][NULL_SAFETY_README], Mockito will generate a
/// `Mock{Type} extends Mock` class for each class to be mocked, in
/// `{name}.mocks.dart`, where `{name}` is the basename of the file in which
/// `@GenerateMocks` is used.
///
/// For example, if `@GenerateMocks([Foo])` is found at the top-level of a Dart
/// library, `foo_test.dart`, then Mockito will generate
/// `class MockFoo extends Mock implements Foo` in a new library,
/// `foo_test.mocks.dart`.
///
/// If the class-to-mock is generic, then the mock will be identically generic.
/// For example, given the class `class Foo<T, U>`, Mockito will generate
/// `class MockFoo<T, U> extends Mock implements Foo<T, U>`.
///
/// Custom mocks can be generated with the `customMocks:` named argument. Each
/// mock is specified with a [MockSpec] object.
///
/// [NULL_SAFETY_README]: https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md
class GenerateMocks {
  final List<Type> classes;
  final List<MockSpec> customMocks;

  const GenerateMocks(this.classes, {this.customMocks = const []});
}

/// A specification of how to mock a specific class.
///
/// The type argument `T` is the class-to-mock. If this class is generic, and no
/// explicit type arguments are given, then the mock class is generic.
/// If the class is generic, and `T` has been specified with type argument(s),
/// the mock class is not generic, and it extends the mocked class using the
/// given type arguments.
///
/// The name of the mock class is either specified with the `as` named argument,
/// or is the name of the class being mocked, prefixed with 'Mock'.
///
/// To use the legacy behavior of returning null for unstubbed methods, use
/// `returnNullOnMissingStub: true`.
///
/// For example, given the generic class, `class Foo<T>`, then this
/// annotation:
///
/// ```dart
/// @GenerateMocks([], customMocks: [
///     MockSpec<Foo>(),
///     MockSpec<Foo<int>>(as: #MockFooOfInt),
/// ])
/// ```
///
/// directs Mockito to generate two mocks:
/// `class MockFoo<T> extends Mocks implements Foo<T>` and
/// `class MockFooOfInt extends Mock implements Foo<int>`.
class MockSpec<T> {
  final Symbol? mockName;

  final bool returnNullOnMissingStub;

  final Set<Symbol> unsupportedMembers;

  final Map<Symbol, Function> fallbackGenerators;

  /// Constructs a custom mock specification.
  ///
  /// Specify a custom name with the [as] parameter.
  ///
  /// If [returnNullOnMissingStub] is true, a real call to a mock method will
  /// return `null` when no stub is found. This may result in a runtime error,
  /// if the return type of the method is non-nullable.
  ///
  /// If the class-to-mock has a member with a non-nullable unknown return type
  /// (such as a type variable, `T`), then mockito cannot generate a valid
  /// override member, unless the member is specified in [unsupportedMembers],
  /// or a fallback implementation is given in [fallbackGenerators].
  ///
  /// If [unsupportedMembers] contains the name of each such member, the mock
  /// class is generated with an override, with throws an exception, for each
  /// member with a non-nullable unknown return type. Such an override cannot be
  /// used with the mockito stubbing and verification APIs, but makes the mock
  /// class a valid implementation of the class-to-mock.
  ///
  /// Each entry in [fallbackGenerators] specifies a mapping from a method name
  /// to a function, with the same signature as the method. This function is
  /// used to generate fallback values when a non-null value needs to be
  /// returned when stubbing or verifying. A fallback value is not ever exposed
  /// in stubbing or verifying; it is an object that mockito's internals can use
  /// as a legal return value.
  const MockSpec({
    Symbol? as,
    this.returnNullOnMissingStub = false,
    this.unsupportedMembers = const {},
    this.fallbackGenerators = const {},
  }) : mockName = as;
}
