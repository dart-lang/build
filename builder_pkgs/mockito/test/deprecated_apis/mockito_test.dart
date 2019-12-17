// Copyright 2016 Dart Mockito authors
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

// ignore_for_file: strong_mode_implicit_dynamic_function

@deprecated
library mockito.test.deprecated_apis.mockito_test;

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _RealClass {
  _RealClass innerObj;
  String methodWithoutArgs() => 'Real';
  String methodWithNormalArgs(int x) => 'Real';
  String methodWithListArgs(List<int> x) => 'Real';
  String methodWithPositionalArgs(int x, [int y]) => 'Real';
  String methodWithNamedArgs(int x, {int y}) => 'Real';
  String methodWithTwoNamedArgs(int x, {int y, int z}) => 'Real';
  String methodWithObjArgs(_RealClass x) => 'Real';
  Future<String> methodReturningFuture() => Future.value('Real');
  Stream<String> methodReturningStream() => Stream.fromIterable(['Real']);
  String get getter => 'Real';
  set setter(String arg) {
    throw StateError('I must be mocked');
  }
}

abstract class Foo {
  String bar();
}

abstract class AbstractFoo implements Foo {
  @override
  String bar() => baz();

  String baz();
}

class MockFoo extends AbstractFoo with Mock {}

class _MockedClass extends Mock implements _RealClass {}

void expectFail(String expectedMessage, void Function() expectedToFail) {
  try {
    expectedToFail();
    fail('It was expected to fail!');
  } catch (e) {
    if (!(e is TestFailure)) {
      rethrow;
    } else {
      if (expectedMessage != e.message) {
        throw TestFailure('Failed, but with wrong message: ${e.message}');
      }
    }
  }
}

String noMatchingCallsFooter = '(If you called `verify(...).called(0);`, '
    'please instead use `verifyNever(...);`.)';

void main() {
  _MockedClass mock;

  setUp(() {
    mock = _MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group('when()', () {
    test('should mock method with argument matcher', () {
      when(mock.methodWithNormalArgs(typed(argThat(greaterThan(100)))))
          .thenReturn('A lot!');
      expect(mock.methodWithNormalArgs(100), isNull);
      expect(mock.methodWithNormalArgs(101), equals('A lot!'));
    });

    test('should mock method with any argument matcher', () {
      when(mock.methodWithNormalArgs(typed(any))).thenReturn('A lot!');
      expect(mock.methodWithNormalArgs(100), equals('A lot!'));
      expect(mock.methodWithNormalArgs(101), equals('A lot!'));
    });

    test('should mock method with any list argument matcher', () {
      when(mock.methodWithListArgs(typed(any))).thenReturn('A lot!');
      expect(mock.methodWithListArgs([42]), equals('A lot!'));
      expect(mock.methodWithListArgs([43]), equals('A lot!'));
    });

    test('should mock method with mix of argument matchers and real things',
        () {
      when(mock.methodWithPositionalArgs(typed(argThat(greaterThan(100))), 17))
          .thenReturn('A lot with 17');
      expect(mock.methodWithPositionalArgs(100, 17), isNull);
      expect(mock.methodWithPositionalArgs(101, 18), isNull);
      expect(mock.methodWithPositionalArgs(101, 17), equals('A lot with 17'));
    });

    //no need to mock setter, except if we will have spies later...
    test('should mock method with thrown result', () {
      when(mock.methodWithNormalArgs(typed(any))).thenThrow(StateError('Boo'));
      expect(() => mock.methodWithNormalArgs(42), throwsStateError);
    });

    test('should mock method with calculated result', () {
      when(mock.methodWithNormalArgs(typed(any))).thenAnswer(
          (Invocation inv) => inv.positionalArguments[0].toString());
      expect(mock.methodWithNormalArgs(43), equals('43'));
      expect(mock.methodWithNormalArgs(42), equals('42'));
    });

    test('should mock method with calculated result', () {
      when(mock.methodWithNormalArgs(typed(argThat(equals(43)))))
          .thenReturn('43');
      when(mock.methodWithNormalArgs(typed(argThat(equals(42)))))
          .thenReturn('42');
      expect(mock.methodWithNormalArgs(43), equals('43'));
    });

    test('should mock hashCode', () {
      named(mock, hashCode: 42);
      expect(mock.hashCode, equals(42));
    });

    test('should have toString as name when it is not mocked', () {
      named(mock, name: 'Cat');
      expect(mock.toString(), equals('Cat'));
    });

    test('should mock equals between mocks when givenHashCode is equals', () {
      var anotherMock = named(_MockedClass(), hashCode: 42);
      named(mock, hashCode: 42);
      expect(mock == anotherMock, isTrue);
    });
  });
}
