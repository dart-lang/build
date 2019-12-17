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
library mockito.test.deprecated_apis.until_called_test;

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
  String typeParameterizedFn(List<int> w, List<int> x,
          [List<int> y, List<int> z]) =>
      'Real';
  String typeParameterizedNamedFn(List<int> w, List<int> x,
          {List<int> y, List<int> z}) =>
      'Real';
  String get getter => 'Real';
  set setter(String arg) {
    throw StateError('I must be mocked');
  }
}

class CallMethodsEvent {}

/// Listens on a stream and upon any event calls all methods in [_RealClass].
class _RealClassController {
  final _RealClass _realClass;

  _RealClassController(
      this._realClass, StreamController<CallMethodsEvent> streamController) {
    streamController.stream.listen(_callAllMethods);
  }

  Future<Null> _callAllMethods(_) async {
    _realClass
      ..methodWithoutArgs()
      ..methodWithNormalArgs(1)
      ..methodWithListArgs([1, 2])
      ..methodWithPositionalArgs(1, 2)
      ..methodWithNamedArgs(1, y: 2)
      ..methodWithTwoNamedArgs(1, y: 2, z: 3)
      ..methodWithObjArgs(_RealClass())
      ..typeParameterizedFn([1, 2], [3, 4], [5, 6], [7, 8])
      ..typeParameterizedNamedFn([1, 2], [3, 4], y: [5, 6], z: [7, 8])
      ..getter
      ..setter = 'A';
  }
}

class MockedClass extends Mock implements _RealClass {}

void main() {
  MockedClass mock;

  setUp(() {
    mock = MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group('untilCalled', () {
    var streamController = StreamController<CallMethodsEvent>.broadcast();

    group('on methods already called', () {
      test('waits for method with normal args', () async {
        mock.methodWithNormalArgs(1);

        await untilCalled(mock.methodWithNormalArgs(typed(any)));

        verify(mock.methodWithNormalArgs(typed(any))).called(1);
      });

      test('waits for method with list args', () async {
        mock.methodWithListArgs([1]);

        await untilCalled(mock.methodWithListArgs(typed(any)));

        verify(mock.methodWithListArgs(typed(any))).called(1);
      });

      test('waits for method with positional args', () async {
        mock.methodWithPositionalArgs(1, 2);

        await untilCalled(
            mock.methodWithPositionalArgs(typed(any), typed(any)));

        verify(mock.methodWithPositionalArgs(typed(any), typed(any))).called(1);
      });

      test('waits for method with named args', () async {
        mock.methodWithNamedArgs(1, y: 2);

        await untilCalled(mock.methodWithNamedArgs(any, y: anyNamed('y')));

        verify(mock.methodWithNamedArgs(any, y: anyNamed('y'))).called(1);
      });

      test('waits for method with obj args', () async {
        mock.methodWithObjArgs(_RealClass());

        await untilCalled(mock.methodWithObjArgs(typed(any)));

        verify(mock.methodWithObjArgs(typed(any))).called(1);
      });

      test('waits for function with positional parameters', () async {
        mock.typeParameterizedFn([1, 2], [3, 4], [5, 6], [7, 8]);

        await untilCalled(mock.typeParameterizedFn(
            typed(any), typed(any), typed(any), typed(any)));

        verify(mock.typeParameterizedFn(
                typed(any), typed(any), typed(any), typed(any)))
            .called(1);
      });
    });

    group('on methods not yet called', () {
      setUp(() {
        _RealClassController(mock, streamController);
      });

      test('waits for method with normal args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(mock.methodWithNormalArgs(typed(any)));

        await untilCalled(mock.methodWithNormalArgs(typed(any)));

        verify(mock.methodWithNormalArgs(typed(any))).called(1);
      });

      test('waits for method with list args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(mock.methodWithListArgs(typed(any)));

        await untilCalled(mock.methodWithListArgs(typed(any)));

        verify(mock.methodWithListArgs(typed(any))).called(1);
      });

      test('waits for method with positional args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(mock.methodWithPositionalArgs(typed(any), typed(any)));

        await untilCalled(
            mock.methodWithPositionalArgs(typed(any), typed(any)));

        verify(mock.methodWithPositionalArgs(typed(any), typed(any))).called(1);
      });

      test('waits for method with obj args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(mock.methodWithObjArgs(typed(any)));

        await untilCalled(mock.methodWithObjArgs(typed(any)));

        verify(mock.methodWithObjArgs(typed(any))).called(1);
      });

      test('waits for function with positional parameters', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(mock.typeParameterizedFn(
            typed(any), typed(any), typed(any), typed(any)));

        await untilCalled(mock.typeParameterizedFn(
            typed(any), typed(any), typed(any), typed(any)));

        verify(mock.typeParameterizedFn(
                typed(any), typed(any), typed(any), typed(any)))
            .called(1);
      });
    });
  });
}
