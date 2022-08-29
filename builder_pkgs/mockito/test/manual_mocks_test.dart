// Copyright 2020 Dart Mockito authors
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

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class RealClass {
  // Non-nullable parameters
  String? nonNullableParam(int x) => 'Real';
  String? nonNullableParam2<T>(int x) => 'Real';
  String? nonNullableParam3<T extends Object>(T x) => 'Real';
  String? operator +(int x) => 'Real';

  // Non-nullable return types
  int nonNullableReturn(int? x) => 0;
  T nonNullableReturn2<T>(T t) => t;
  Future<int> nonNullableFutureReturn(int? x) => Future.value(0);
  int get getter => 0;

  // Methods which are not manually mocked in `MockedClass`
  String? notMockedNonNullableParam(int x) => 'Real';
  int notMockedNonNullableReturn() => 0;
}

class MockedClass extends Mock implements RealClass {
  @override
  String? nonNullableParam(int? x) =>
      super.noSuchMethod(Invocation.method(#nonNullableParam, [x])) as String?;

  @override
  String? nonNullableParam2<T>(int? x) =>
      super.noSuchMethod(Invocation.genericMethod(#nonNullableParam2, [T], [x]))
          as String?;

  @override
  String? nonNullableParam3<T extends Object>(T? x) =>
      super.noSuchMethod(Invocation.genericMethod(#nonNullableParam3, [T], [x]))
          as String?;

  @override
  String? operator +(int? x) =>
      super.noSuchMethod(Invocation.method(#+, [x])) as String?;

  @override
  int nonNullableReturn(int? x) =>
      super.noSuchMethod(Invocation.method(#nonNullableReturn, [x]),
          returnValue: 1) as int;

  // A generic return type is very tricky to work with in a manually mocked
  // method. What value can be passed as the second argument to
  // `super.noSuchMethod` which will always act as a non-nullable T? We
  // "require" a named parameter, `sentinal` as this value. The named parameter
  // is optional, so that the override is still legal.
  @override
  T nonNullableReturn2<T>(T? x, {T? sentinal}) =>
      super.noSuchMethod(Invocation.method(#nonNullableReturn2, [x]),
          returnValue: sentinal!) as T;

  @override
  Future<int> nonNullableFutureReturn(int? x) =>
      super.noSuchMethod(Invocation.method(#nonNullableFutureReturn, [x]),
          returnValue: Future.value(1)) as Future<int>;

  @override
  int get getter =>
      super.noSuchMethod(Invocation.getter(#getter), returnValue: 1) as int;
}

void main() {
  late MockedClass mock;

  setUp(() {
    mock = MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group('when()', () {
    test(
        'cannot operate on method with non-nullable params without a manual '
        'mock', () {
      // Normally this use of `any` would be a static error. To push forward to
      // reveal the runtime error, we cast as dynamic.
      expect(
          () => when(mock.notMockedNonNullableParam((any as dynamic) as int))
              .thenReturn('Mock'),
          throwsA(TypeMatcher<TypeError>()));
    });

    test(
        'cannot operate on method with non-nullable return type without a '
        'manual mock', () {
      expect(() => when(mock.notMockedNonNullableReturn()).thenReturn(7),
          throwsA(TypeMatcher<TypeError>()));
    });

    test('should mock method with non-nullable params', () {
      when(mock.nonNullableParam(42)).thenReturn('Mock');
      expect(mock.nonNullableParam(43), isNull);
      expect(mock.nonNullableParam(42), equals('Mock'));
    });

    test(
        'should mock method with non-nullable params with "any" argument '
        'matcher', () {
      when(mock.nonNullableParam(any)).thenReturn('Mock');
      expect(mock.nonNullableParam(100), equals('Mock'));
      expect(mock.nonNullableParam(101), equals('Mock'));
    });

    test(
        'should mock generic method with non-nullable params with "any" '
        'argument matcher', () {
      when(mock.nonNullableParam2(any)).thenReturn('Mock');
      expect(mock.nonNullableParam2(100), equals('Mock'));
      expect(mock.nonNullableParam2(101), equals('Mock'));
    });

    test(
        'should mock generic method with non-nullable generic params with '
        '"any" argument matcher', () {
      when(mock.nonNullableParam3<int>(any)).thenReturn('Mock');
      expect(mock.nonNullableParam3<int>(100), equals('Mock'));
      expect(mock.nonNullableParam3<int>(101), equals('Mock'));
    });

    test('should mock operator with non-nullable param', () {
      when(mock + any).thenReturn('Mock');
      expect(mock + 42, equals('Mock'));
    });

    test('should mock method with non-nullable return type', () {
      when(mock.nonNullableReturn(42)).thenReturn(7);
      expect(mock.nonNullableReturn(42), equals(7));
    });

    test('should mock generic method with non-nullable return type', () {
      when(mock.nonNullableReturn2(42, sentinal: 99)).thenReturn(7);
      expect(mock.nonNullableReturn2(42, sentinal: 99), equals(7));
    });

    test('should mock method with non-nullable Future return type', () async {
      when(mock.nonNullableFutureReturn(42)).thenAnswer((_) async => 7);
      expect(await mock.nonNullableFutureReturn(42), equals(7));
    });

    test('should mock getter', () {
      when(mock.getter).thenReturn(7);
      expect(mock.getter, equals(7));
    });
  });

  group('real calls', () {
    test(
        'should throw a TypeError on a call to a function with a non-nullable '
        'return type without a matching stub', () {
      expect(
          () => mock.nonNullableReturn(43), throwsA(TypeMatcher<TypeError>()));
    });

    test(
        'should throw a NoSuchMethodError on a call without a matching stub, '
        'using `throwOnMissingStub` behavior', () {
      throwOnMissingStub(mock);
      expect(() => mock.nonNullableReturn(43),
          throwsA(TypeMatcher<MissingStubError>()));
    });
  });

  group('verify()', () {
    test('should verify method with non-nullable params', () {
      mock.nonNullableParam(42);
      verify(mock.nonNullableParam(42)).called(1);
    });

    test(
        'should verify method with non-nullable params with "any" argument '
        'matcher', () {
      mock.nonNullableParam(42);
      verify(mock.nonNullableParam(any)).called(1);
    });

    test('should verify method with non-nullable return type', () {
      when(mock.nonNullableReturn(42)).thenReturn(7);
      mock.nonNullableReturn(42);
      verify(mock.nonNullableReturn(42)).called(1);
    });
  });

  group('verifyNever()', () {
    test('should verify method with non-nullable params', () {
      mock.nonNullableParam(42);
      verifyNever(mock.nonNullableParam(43));
    });

    test(
        'should verify method with non-nullable params with "any" argument '
        'matcher', () {
      verifyNever(mock.nonNullableParam(any));
    });

    test('should verify method with non-nullable return type', () {
      verifyNever(mock.nonNullableReturn(42));
    });
  });
}
