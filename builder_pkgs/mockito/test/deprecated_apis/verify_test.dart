// Copyright 2018 Dart Mockito authors
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
library mockito.test.deprecated_apis.verify_test;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _RealClass {
  _RealClass innerObj;
  String methodWithoutArgs() => 'Real';
  String methodWithNormalArgs(int x) => 'Real';
  String methodWithListArgs(List<int> x) => 'Real';
  String methodWithOptionalArg([int x]) => 'Real';
  String methodWithPositionalArgs(int x, [int y]) => 'Real';
  String methodWithNamedArgs(int x, {int y}) => 'Real';
  String methodWithOnlyNamedArgs({int y, int z}) => 'Real';
  String methodWithObjArgs(_RealClass x) => 'Real';
  String get getter => 'Real';
  set setter(String arg) {
    throw StateError('I must be mocked');
  }

  String methodWithLongArgs(LongToString a, LongToString b,
          {LongToString c, LongToString d}) =>
      'Real';
}

class LongToString {
  final List aList;
  final Map aMap;
  final String aString;

  LongToString(this.aList, this.aMap, this.aString);

  @override
  String toString() => 'LongToString<\n'
      '    aList: $aList\n'
      '    aMap: $aMap\n'
      '    aString: $aString\n'
      '>';
}

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

  group('verify', () {
    test('should mock method with argument matcher', () {
      mock.methodWithNormalArgs(100);
      expectFail(
          'No matching calls. All calls: '
          '_MockedClass.methodWithNormalArgs(100)\n'
          '$noMatchingCallsFooter', () {
        verify(mock.methodWithNormalArgs(typed(argThat(greaterThan(100)))));
      });
      verify(
          mock.methodWithNormalArgs(typed(argThat(greaterThanOrEqualTo(100)))));
    });

    test('should mock method with mix of argument matchers and real things',
        () {
      mock.methodWithPositionalArgs(100, 17);
      expectFail(
          'No matching calls. All calls: '
          '_MockedClass.methodWithPositionalArgs(100, 17)\n'
          '$noMatchingCallsFooter', () {
        verify(mock.methodWithPositionalArgs(
            typed(argThat(greaterThanOrEqualTo(100))), 18));
      });
      expectFail(
          'No matching calls. All calls: '
          '_MockedClass.methodWithPositionalArgs(100, 17)\n'
          '$noMatchingCallsFooter', () {
        verify(mock.methodWithPositionalArgs(
            typed(argThat(greaterThan(100))), 17));
      });
      verify(mock.methodWithPositionalArgs(
          typed(argThat(greaterThanOrEqualTo(100))), 17));
    });

    test('should mock method with mock args', () {
      var m1 = named(_MockedClass(), name: 'm1');
      mock.methodWithObjArgs(m1);
      expectFail(
          'No matching calls. All calls: _MockedClass.methodWithObjArgs(m1)\n'
          '$noMatchingCallsFooter', () {
        verify(mock.methodWithObjArgs(_MockedClass()));
      });
      verify(mock.methodWithObjArgs(m1));
    });
  });
}
