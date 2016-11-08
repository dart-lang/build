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

import 'package:mockito/src/mock.dart' show resetMockitoState;
import 'package:mockito/mirrors.dart';
import 'package:test/test.dart';

import 'mockito_test.dart' show MockedClass, RealClass;

void main() {
  RealClass mock;

  setUp(() {
    mock = new MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group("spy", () {
    setUp(() {
      mock = spy/*<RealClass>*/(new MockedClass(), new RealClass());
    });

    test("should delegate to real object by default", () {
      expect(mock.methodWithoutArgs(), 'Real');
    });
    test("should record interactions delegated to real object", () {
      mock.methodWithoutArgs();
      verify(mock.methodWithoutArgs());
    });
    test("should behave as mock when expectation are set", () {
      when(mock.methodWithoutArgs()).thenReturn('Spied');
      expect(mock.methodWithoutArgs(), 'Spied');
    });
  });
}
