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

/// An annotation to direct Mockito to generate mock classes.
///
/// During [code generation][NULL_SAFETY_README], Mockito will generate a
/// `Mock{Type} extends Mock` class for each class to be mocked, in
/// `{name}.mocks.dart`, where `{name}` is the basename of the file in which
/// `@GenerateNiceMocks` is used.
///
/// For example, if `@GenerateNiceMocks([MockSpec<Foo>()])` is found at
/// the top-level of a Dart library, `foo_test.dart`, then Mockito will
/// generate `class MockFoo extends Mock implements Foo` in a new library,
/// `foo_test.mocks.dart`.
///
/// If the class-to-mock is generic, then the mock will be identically generic.
/// For example, given the class `class Foo<T, U>`, Mockito will generate
/// `class MockFoo<T, U> extends Mock implements Foo<T, U>`.
///
/// `@GenerateNiceMocks` is different from `@GenerateMocks` in two ways:
///   - only `MockSpec`s are allowed in the argument list
///   - generated mocks won't throw on unstubbed method calls by default,
///     instead some value appropriate for the target type will be
///     returned.
///
/// [NULL_SAFETY_README]: https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md
class GenerateNiceMocks {
  final List<MockSpec> mocks;
  const GenerateNiceMocks(this.mocks);
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

  final List<Type> mixins;

  @Deprecated('Specify "missing stub" behavior with the [onMissingStub] '
      'parameter.')
  final bool returnNullOnMissingStub;

  final OnMissingStub? onMissingStub;

  final Set<Symbol> unsupportedMembers;

  final Map<Symbol, Function> fallbackGenerators;

  /// Constructs a custom mock specification.
  ///
  /// Specify a custom name with the [as] parameter.
  ///
  /// If [onMissingStub] is specified as [OnMissingStub.returnNull],
  /// (or if the deprecated parameter [returnNullOnMissingStub] is `true`), then
  /// a real call to a mock method (or getter) will return `null` when no stub
  /// is found. This may result in a runtime error, if the return type of the
  /// method (or the getter) is non-nullable.
  ///
  /// If [onMissingStub] is specified as
  /// [OnMissingStub.returnDefault], a real call to a mock method (or
  /// getter) will return a legal value when no stub is found.
  ///
  /// If the class-to-mock has a member with a non-nullable unknown return type
  /// (such as a type variable, `T`), then mockito cannot generate a valid
  /// override member, unless the member is specified in [unsupportedMembers],
  /// or a fallback implementation is given in [fallbackGenerators].
  ///
  /// For each member M in [unsupportedMembers], the mock class will have an
  /// override that throws, which may be useful if the return type T of M is
  /// non-nullable and it's inconvenient to define a fallback generator for M,
  /// e.g. if T is an unknown type variable. Such an override cannot be used
  /// with the mockito stubbing and verification APIs, but makes the mock class
  /// a valid implementation of the class-to-mock.
  ///
  /// Each entry in [fallbackGenerators] specifies a mapping from a method name
  /// to a function, with the same signature as the method. This function is
  /// used to generate fallback values when a non-null value needs to be
  /// returned when stubbing or verifying. A fallback value is not ever exposed
  /// in stubbing or verifying; it is an object that mockito's internals can use
  /// as a legal return value.
  const MockSpec({
    Symbol? as,
    List<Type> mixingIn = const [],
    @Deprecated('Specify "missing stub" behavior with the '
        '[onMissingStub] parameter.')
        this.returnNullOnMissingStub = false,
    this.unsupportedMembers = const {},
    this.fallbackGenerators = const {},
    this.onMissingStub,
  })  : mockName = as,
        mixins = mixingIn;
}

/// Values indicating the action to perform when a real call is made to a mock
/// method (or getter) when no stub is found.
enum OnMissingStub {
  /// An exception should be thrown.
  throwException,

  /// A `null` value should be returned.
  ///
  /// This is considered legacy behavior, as it may result in a runtime error,
  /// if the return type of the method (or the getter) is non-nullable.
  @Deprecated(
      'This is legacy behavior, it may result in runtime errors. Consider using returnDefault instead')
  returnNull,

  /// A legal default value should be returned.
  ///
  /// For basic known types, like `int` and `Future<String>`, a simple value is
  /// returned (like `0` and `Future.value('')`). For unknown user types, an
  /// instance of a fake implementation is returned.
  returnDefault;
}
