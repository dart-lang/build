import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'foo.dart';
import 'foo_sub.dart';
import 'generated_mocks_test.mocks.dart';

T returnsTypeVariableShim<T>() => [1, 1.5].whereType<T>().first!;

T returnsBoundedTypeVariableShim<T extends num?>() =>
    [1, 1.5].whereType<T>().first!;

T returnsTypeVariableFromTwoShim<T, U>() => [1, 1.5].whereType<T>().first!;

T typeVariableFieldShim<T>() =>
    throw UnsupportedError('typeVariableField cannot be used');

T Function(T) returnsGenericFunctionShim<T>() => (T _) => null as T;

@GenerateMocks([
  Foo,
  FooSub,
  Bar
], customMocks: [
  MockSpec<Foo>(as: #MockFooRelaxed, returnNullOnMissingStub: true),
  MockSpec<Foo>(
    as: #MockFooWithDefaults,
    onMissingStub: OnMissingStub.returnDefault,
  ),
  MockSpec<Bar>(as: #MockBarRelaxed, returnNullOnMissingStub: true),
  MockSpec<Baz>(
    as: #MockBazWithUnsupportedMembers,
    unsupportedMembers: {
      #returnsTypeVariable,
      #returnsBoundedTypeVariable,
      #returnsTypeVariableFromTwo,
      #returnsGenericFunction,
      #typeVariableField,
      #$hasDollarInName,
    },
  ),
  MockSpec<Baz>(
    as: #MockBazWithFallbackGenerators,
    fallbackGenerators: {
      #returnsTypeVariable: returnsTypeVariableShim,
      #returnsBoundedTypeVariable: returnsBoundedTypeVariableShim,
      #returnsTypeVariableFromTwo: returnsTypeVariableFromTwoShim,
      #returnsGenericFunction: returnsGenericFunctionShim,
      #typeVariableField: typeVariableFieldShim,
      #$hasDollarInName: returnsTypeVariableShim,
    },
  ),
  MockSpec<HasPrivate>(mixingIn: [HasPrivateMixin]),
])
@GenerateNiceMocks([MockSpec<Foo>(as: #MockFooNice)])
void main() {
  group('for a generated mock,', () {
    late MockFoo<Object> foo;
    late FooSub fooSub;

    setUp(() {
      foo = MockFoo();
      fooSub = MockFooSub();
    });

    tearDown(() {
      // In some of the tests that expect an Error to be thrown, Mockito's
      // global state can become invalid. Reset it.
      resetMockitoState();
    });

    test('a method with a positional parameter can be stubbed', () {
      when(foo.positionalParameter(42)).thenReturn('Stubbed');
      expect(foo.positionalParameter(42), equals('Stubbed'));
    });

    test('a method with a named parameter can be stubbed', () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(foo.namedParameter(x: 42), equals('Stubbed'));
    });

    test('a getter can be stubbed', () {
      when(foo.getter).thenReturn('Stubbed');
      expect(foo.getter, equals('Stubbed'));
    });

    test('an operator can be stubbed', () {
      when(foo + 1).thenReturn(0);
      expect(foo + 1, equals(0));
    });

    test('a method with a parameter with a default value can be stubbed', () {
      when(foo.parameterWithDefault(42)).thenReturn('Stubbed');
      expect(foo.parameterWithDefault(42), equals('Stubbed'));

      when(foo.parameterWithDefault()).thenReturn('Default');
      expect(foo.parameterWithDefault(), equals('Default'));

      const foo2 = FooSub();
      when(foo.parameterWithDefault2(foo2)).thenReturn('Stubbed');
      expect(foo.parameterWithDefault2(foo2), equals('Stubbed'));

      when(foo.parameterWithDefault2()).thenReturn('Default');
      expect(foo.parameterWithDefault2(), equals('Default'));
    });

    test(
        'a method with a parameter with a default value factory redirect can '
        'be stubbed', () {
      const foo2 = FooSub2<int>();
      when(foo.parameterWithDefaultFactoryRedirect(foo2)).thenReturn('Stubbed');
      expect(foo.parameterWithDefaultFactoryRedirect(foo2), equals('Stubbed'));

      when(foo.parameterWithDefaultFactoryRedirect()).thenReturn('Default');
      expect(foo.parameterWithDefaultFactoryRedirect(), equals('Default'));
    });

    test('an inherited method can be stubbed', () {
      when(fooSub.positionalParameter(42)).thenReturn('Stubbed');
      expect(fooSub.positionalParameter(42), equals('Stubbed'));
    });

    test('a setter can be called without stubbing', () {
      expect(() => foo.setter = 7, returnsNormally);
    });

    test('a method which returns void can be called without stubbing', () {
      expect(() => foo.returnsVoid(), returnsNormally);
    });

    test('a method which returns Future<void> can be called without stubbing',
        () {
      expect(() => foo.returnsFutureVoid(), returnsNormally);
    });

    test('a method which returns Future<void>? can be called without stubbing',
        () {
      expect(() => foo.returnsNullableFutureVoid(), returnsNormally);
    });

    test(
        'a method with a non-nullable positional parameter accepts an argument '
        'matcher while stubbing', () {
      when(foo.positionalParameter(any)).thenReturn('Stubbed');
      expect(foo.positionalParameter(42), equals('Stubbed'));
    });

    test(
        'a method with a non-nullable named parameter accepts an argument '
        'matcher while stubbing', () {
      when(foo.namedParameter(x: anyNamed('x'))).thenReturn('Stubbed');
      expect(foo.namedParameter(x: 42), equals('Stubbed'));
    });

    test(
        'a method with a non-nullable parameter accepts an argument matcher '
        'while verifying', () {
      when(foo.positionalParameter(any)).thenReturn('Stubbed');
      foo.positionalParameter(42);
      expect(() => verify(foo.positionalParameter(any)), returnsNormally);
    });

    test('a method with a non-nullable parameter can capture an argument', () {
      when(foo.positionalParameter(any)).thenReturn('Stubbed');
      foo.positionalParameter(42);
      var captured = verify(foo.positionalParameter(captureAny)).captured;
      expect(captured[0], equals(42));
    });

    test('an unstubbed method throws', () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(
        () => foo.namedParameter(x: 43),
        throwsA(TypeMatcher<MissingStubError>().having((e) => e.toString(),
            'toString()', contains('namedParameter({x: 43})'))),
      );
    });

    test('an unstubbed getter throws', () {
      expect(
        () => foo.getter,
        throwsA(TypeMatcher<MissingStubError>()
            .having((e) => e.toString(), 'toString()', contains('getter'))),
      );
    });
  });

  group('for a generated mock using unsupportedMembers', () {
    late Baz baz;

    setUp(() {
      baz = MockBazWithUnsupportedMembers();
    });

    test('a real method call throws', () {
      expect(() => baz.returnsTypeVariable(), throwsUnsupportedError);
    });

    test('a real getter call (or field access) throws', () {
      expect(() => baz.typeVariableField, throwsUnsupportedError);
    });

    test('a real call to a method whose name has a \$ in it throws', () {
      expect(() => baz.$hasDollarInName(), throwsUnsupportedError);
    });
  });

  group('for a generated mock using fallbackGenerators,', () {
    late Baz baz;

    setUp(() {
      baz = MockBazWithFallbackGenerators();
    });

    test('a method with a type variable return type can be called', () {
      when(baz.returnsTypeVariable()).thenReturn(3);
      baz.returnsTypeVariable();
    });

    test('a method with a bounded type variable return type can be called', () {
      when(baz.returnsBoundedTypeVariable()).thenReturn(3);
      baz.returnsBoundedTypeVariable();
    });

    test(
        'a method with multiple type parameters and a type variable return '
        'type can be called', () {
      when(baz.returnsTypeVariable()).thenReturn(3);
      baz.returnsTypeVariable();
    });
  });

  group('for a generated mock using returnNullOnMissingStub,', () {
    late Foo<Object> foo;

    setUp(() {
      foo = MockFooRelaxed();
    });

    test('an unstubbed method returning a non-nullable type throws a TypeError',
        () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(
          () => foo.namedParameter(x: 43), throwsA(TypeMatcher<TypeError>()));
    });

    test('an unstubbed getter returning a non-nullable type throws a TypeError',
        () {
      expect(() => foo.getter, throwsA(TypeMatcher<TypeError>()));
    });

    test('an unstubbed method returning a nullable type returns null', () {
      when(foo.nullableMethod(42)).thenReturn('Stubbed');
      expect(foo.nullableMethod(43), isNull);
    });

    test('an unstubbed getter returning a nullable type returns null', () {
      expect(foo.nullableGetter, isNull);
    });
  });

  group('for a generated mock using OnMissingStub.returnDefault,', () {
    late Foo<Object> foo;

    setUp(() {
      foo = MockFooWithDefaults();
    });

    test('an unstubbed method returns a value', () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(foo.namedParameter(x: 43), equals(''));
    });

    test('an unstubbed getter returns a value', () {
      expect(foo.getter, equals(''));
    });
  });

  group('for a generated nice mock', () {
    late Foo<Object> foo;

    setUp(() {
      foo = MockFooNice();
    });

    test('an unstubbed method returns a value', () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(foo.namedParameter(x: 43), equals(''));
    });

    test('an unstubbed getter returns a value', () {
      expect(foo.getter, equals(''));
    });

    test('an unstubbed method returning non-core type returns a fake', () {
      when(foo.returnsBar(42)).thenReturn(Bar());
      expect(foo.returnsBar(43), isA<SmartFake>());
    });

    test('a fake throws a FakeUsedError if a getter is called', () {
      when(foo.returnsBar(42)).thenReturn(Bar());
      final bar = foo.returnsBar(43);
      expect(
          () => bar.x,
          throwsA(isA<FakeUsedError>().having(
              (e) => e.toString(), 'toString()', contains('returnsBar(43)'))));
    });

    test('a fake throws a FakeUsedError if a method is called', () {
      when(foo.returnsBar(42)).thenReturn(Bar());
      final bar = foo.returnsBar(43);
      expect(
          () => bar.f(),
          throwsA(isA<FakeUsedError>().having(
              (e) => e.toString(), 'toString()', contains('returnsBar(43)'))));
    });
  });

  test('a generated mock can be used as a stub argument', () {
    var foo = MockFoo();
    var bar = MockBar();
    when(foo.methodWithBarArg(bar)).thenReturn('mocked result');
    expect(foo.methodWithBarArg(bar), equals('mocked result'));
  });

  test(
      'a generated mock which returns null on missing stubs can be used as a '
      'stub argument', () {
    var foo = MockFooRelaxed();
    var bar = MockBarRelaxed();
    when(foo.methodWithBarArg(bar)).thenReturn('mocked result');
    expect(foo.methodWithBarArg(bar), equals('mocked result'));
  });

  test('a generated mock with a mixed in type can use mixed in members', () {
    var hasPrivate = MockHasPrivate();
    // This should not throw, when `setPrivate` accesses a private member on
    // `hasPrivate`.
    setPrivate(hasPrivate);
  });
}
