import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'foo.dart';
import 'foo_sub.dart';
import 'generated_mocks_test.mocks.dart';

@GenerateMocks([
  Foo,
  FooSub,
  Bar
], customMocks: [
  MockSpec<Foo>(
    as: #MockFooWithDefaults,
    onMissingStub: OnMissingStub.returnDefault,
  ),
  MockSpec<Baz>(
    as: #MockBazWithUnsupportedMembers,
    unsupportedMembers: {
      #returnsPrivate,
      #privateArg,
      #privateTypeField,
      #$hasDollarInName,
    },
  ),
  MockSpec<HasPrivate>(mixingIn: [HasPrivateMixin]),
])
@GenerateNiceMocks(
    [MockSpec<Foo>(as: #MockFooNice), MockSpec<Bar>(as: #MockBarNice)])
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
      final captured = verify(foo.positionalParameter(captureAny)).captured;
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

    test('a method returning Future<T> can be stubbed', () async {
      when(foo.returnsFuture(any)).thenAnswer((_) async => 1);
      expect(await foo.returnsFuture(0), 1);
    });
  });

  group('for a generated mock using unsupportedMembers', () {
    late MockBazWithUnsupportedMembers<Bar> baz;

    setUp(() {
      baz = MockBazWithUnsupportedMembers<Bar>();
    });

    tearDown(() => resetMockitoState());

    test('a real method call that returns private type throws', () {
      expect(() => baz.returnsPrivate(), throwsUnsupportedError);
    });

    test('a real method call that accepts private type throws', () {
      expect(() => baz.privateArg(private), throwsUnsupportedError);
    });

    test('a real getter call (or field access) throws', () {
      expect(() => baz.privateTypeField, throwsUnsupportedError);
    });

    test('a real call to a method whose name has a \$ in it throws', () {
      expect(() => baz.$hasDollarInName(), throwsUnsupportedError);
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
      when(baz.returnsTypeVariableFromTwo()).thenReturn(3);
      baz.returnsTypeVariableFromTwo();
    });

    test(
        'a getter with a type variable return type throws if there is no '
        'dummy value', () {
      expect(() => when(baz.typeVariableField).thenReturn(Bar()),
          throwsA(isA<MissingDummyValueError>()));
    });

    test(
        'a getter with a type variable return type can be called if dummy '
        'value was provided', () {
      provideDummy<Bar>(Bar());
      final bar = Bar();
      when(baz.typeVariableField).thenReturn(bar);
      expect(baz.typeVariableField, bar);
    });
  });

  group('for a generated mock using OnMissingStub.returnDefault,', () {
    late Foo<Object> foo;

    setUp(() {
      foo = MockFooWithDefaults();
    });

    test('an unstubbed method returns a value', () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(
          foo.namedParameter(x: 43),
          contains(Uri.encodeComponent(
              'Dummy String created while calling namedParameter({x: 43})'
                  .replaceAll(' ', '_'))));
    });

    test('an unstubbed getter returns a value', () {
      expect(
          foo.getter,
          contains(Uri.encodeComponent(
              'Dummy String created while calling getter'
                  .replaceAll(' ', '_'))));
    });
  });

  group('for a generated nice mock', () {
    late Foo<Bar> foo;

    setUp(() {
      foo = MockFooNice();
    });

    test('an unstubbed method returns a value', () {
      when(foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(
          foo.namedParameter(x: 43),
          contains(Uri.encodeComponent(
              'Dummy String created while calling namedParameter({x: 43})'
                  .replaceAll(' ', '_'))));
    });

    test('an unstubbed getter returns a value', () {
      expect(
          foo.getter,
          contains(Uri.encodeComponent(
              'Dummy String created while calling getter'
                  .replaceAll(' ', '_'))));
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
    group('a method returning Future<T>', () {
      final bar = Bar();
      tearDown(() {
        resetMockitoState();
      });
      test('returns a fake future if unstubbed', () {
        expect(foo.returnsFuture(bar), isA<SmartFake>());
      });
      test('returned fake future cannot be awaited', () async {
        try {
          await foo.returnsFuture(bar);
          // Expect it to throw.
          expect('This code should not be reached', false);
        } catch (e) {
          expect(e, isA<FakeUsedError>());
        }
      });
      test('with provideDummy returned value can be awaited', () async {
        provideDummy<Bar>(bar);
        expect(await foo.returnsFuture(MockBar()), bar);
      });
    });
  });

  test('a generated mock can be used as a stub argument', () {
    final foo = MockFoo();
    final bar = MockBar();
    when(foo.methodWithBarArg(bar)).thenReturn('mocked result');
    expect(foo.methodWithBarArg(bar), equals('mocked result'));
  });

  test('a generated nice mock can be used as a stub argument', () {
    final foo = MockFoo();
    final bar = MockBarNice();
    when(foo.methodWithBarArg(bar)).thenReturn('mocked result');
    expect(foo.methodWithBarArg(bar), equals('mocked result'));
  });

  test('a generated mock with a mixed in type can use mixed in members', () {
    final hasPrivate = MockHasPrivate();
    // This should not throw, when `setPrivate` accesses a private member on
    // `hasPrivate`.
    setPrivate(hasPrivate);
  });
}
