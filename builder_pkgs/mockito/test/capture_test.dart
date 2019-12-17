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

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'utils.dart';

class _RealClass {
  _RealClass innerObj;
  String methodWithNormalArgs(int x) => 'Real';
  String methodWithListArgs(List<int> x) => 'Real';
  String methodWithPositionalArgs(int x, [int y]) => 'Real';
  String methodWithTwoNamedArgs(int x, {int y, int z}) => 'Real';
  set setter(String arg) {
    throw StateError('I must be mocked');
  }
}

class _MockedClass extends Mock implements _RealClass {}

void main() {
  _MockedClass mock;

  var isNsmForwarding = assessNsmForwarding();

  setUp(() {
    mock = _MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group('capture', () {
    test('captureAny should match anything', () {
      mock.methodWithNormalArgs(42);
      expect(verify(mock.methodWithNormalArgs(captureAny)).captured.single,
          equals(42));
    });

    test('captureThat should match some things', () {
      mock.methodWithNormalArgs(42);
      mock.methodWithNormalArgs(44);
      mock.methodWithNormalArgs(43);
      mock.methodWithNormalArgs(45);
      expect(
          verify(mock.methodWithNormalArgs(captureThat(lessThan(44)))).captured,
          equals([42, 43]));
    });

    test('should capture list arguments', () {
      mock.methodWithListArgs([42]);
      expect(verify(mock.methodWithListArgs(captureAny)).captured.single,
          equals([42]));
    });

    test('should capture setter invocations', () {
      mock.setter = 'value';
      expect(verify(mock.setter = captureAny).captured, equals(['value']));
    });

    test('should capture multiple arguments', () {
      mock.methodWithPositionalArgs(1, 2);
      expect(
          verify(mock.methodWithPositionalArgs(captureAny, captureAny))
              .captured,
          equals([1, 2]));
    });

    test('should capture with matching arguments', () {
      mock.methodWithPositionalArgs(1);
      mock.methodWithPositionalArgs(2, 3);
      var expectedCaptures = isNsmForwarding ? [1, null, 2, 3] : [2, 3];
      expect(
          verify(mock.methodWithPositionalArgs(captureAny, captureAny))
              .captured,
          equals(expectedCaptures));
    });

    test('should capture multiple invocations', () {
      mock.methodWithNormalArgs(1);
      mock.methodWithNormalArgs(2);
      expect(verify(mock.methodWithNormalArgs(captureAny)).captured,
          equals([1, 2]));
    });

    test('should capture invocations with named arguments', () {
      mock.methodWithTwoNamedArgs(1, y: 42, z: 43);
      expect(
          verify(mock.methodWithTwoNamedArgs(any,
                  y: captureAnyNamed('y'), z: captureAnyNamed('z')))
              .captured,
          equals([42, 43]));
    });

    test('should capture invocations with named arguments', () {
      mock.methodWithTwoNamedArgs(1, y: 42, z: 43);
      mock.methodWithTwoNamedArgs(1, y: 44, z: 45);
      expect(
          verify(mock.methodWithTwoNamedArgs(any,
                  y: captureAnyNamed('y'), z: captureAnyNamed('z')))
              .captured,
          equals([42, 43, 44, 45]));
    });

    test('should capture invocations with out-of-order named arguments', () {
      mock.methodWithTwoNamedArgs(1, z: 42, y: 43);
      mock.methodWithTwoNamedArgs(1, y: 44, z: 45);
      expect(
          verify(mock.methodWithTwoNamedArgs(any,
                  y: captureAnyNamed('y'), z: captureAnyNamed('z')))
              .captured,
          equals([43, 42, 44, 45]));
    });
  });
}
