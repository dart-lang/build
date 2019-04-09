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
library mockito.test.deprecated_apis.capture_test;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../utils.dart';

class _RealClass {
  _RealClass innerObj;
  String methodWithNormalArgs(int x) => 'Real';
  String methodWithListArgs(List<int> x) => 'Real';
  String methodWithPositionalArgs(int x, [int y]) => 'Real';
  set setter(String arg) {
    throw StateError('I must be mocked');
  }
}

class MockedClass extends Mock implements _RealClass {}

void main() {
  MockedClass mock;

  var isNsmForwarding = assessNsmForwarding();

  setUp(() {
    mock = MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group('capture', () {
    test('captureAny should match anything', () {
      mock.methodWithNormalArgs(42);
      expect(
          verify(mock.methodWithNormalArgs(typed(captureAny))).captured.single,
          equals(42));
    });

    test('captureThat should match some things', () {
      mock.methodWithNormalArgs(42);
      mock.methodWithNormalArgs(44);
      mock.methodWithNormalArgs(43);
      mock.methodWithNormalArgs(45);
      expect(
          verify(mock.methodWithNormalArgs(typed(captureThat(lessThan(44)))))
              .captured,
          equals([42, 43]));
    });

    test('should capture list arguments', () {
      mock.methodWithListArgs([42]);
      expect(verify(mock.methodWithListArgs(typed(captureAny))).captured.single,
          equals([42]));
    });

    test('should capture multiple arguments', () {
      mock.methodWithPositionalArgs(1, 2);
      expect(
          verify(mock.methodWithPositionalArgs(
                  typed(captureAny), typed(captureAny)))
              .captured,
          equals([1, 2]));
    });

    test('should capture with matching arguments', () {
      mock.methodWithPositionalArgs(1);
      mock.methodWithPositionalArgs(2, 3);
      var expectedCaptures = isNsmForwarding ? [1, null, 2, 3] : [2, 3];
      expect(
          verify(mock.methodWithPositionalArgs(
                  typed(captureAny), typed(captureAny)))
              .captured,
          equals(expectedCaptures));
    });

    test('should capture multiple invocations', () {
      mock.methodWithNormalArgs(1);
      mock.methodWithNormalArgs(2);
      expect(verify(mock.methodWithNormalArgs(typed(captureAny))).captured,
          equals([1, 2]));
    });
  });
}
