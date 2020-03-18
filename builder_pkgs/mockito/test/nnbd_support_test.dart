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

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class Foo {
  String /*?*/ returnsNullableString() => 'Hello';

  // TODO(srawlins): When it becomes available, opt this test library into NNBD,
  // and make this method really return a non-nullable String.
  String /*!*/ returnsNonNullableString() => 'Hello';
}

class MockFoo extends Mock implements Foo {
  @override
  String /*!*/ returnsNonNullableString() {
    return super.noSuchMethod(
        Invocation.method(#returnsNonNullableString, []), 'Dummy') as String;
  }
}

void main() {
  MockFoo mock;

  setUp(() {
    mock = MockFoo();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group('Using nSM out of the box,', () {
    test('nSM returns the dummy value during method stubbing', () {
      // Trigger method stubbing.
      final whenCall = when;
      final stubbedResponse = mock.returnsNullableString();
      expect(stubbedResponse, equals(null));
      whenCall(stubbedResponse).thenReturn('A');
    });

    test('nSM returns the dummy value during method call verification', () {
      when(mock.returnsNullableString()).thenReturn('A');

      // Make a real call.
      final realResponse = mock.returnsNullableString();
      expect(realResponse, equals('A'));

      // Trigger method call verification.
      final verifyCall = verify;
      final verificationResponse = mock.returnsNullableString();
      expect(verificationResponse, equals(null));
      verifyCall(verificationResponse);
    });

    test(
        'nSM returns the dummy value during method call verification, using '
        'verifyNever', () {
      // Trigger method call verification.
      final verifyNeverCall = verifyNever;
      final verificationResponse = mock.returnsNullableString();
      expect(verificationResponse, equals(null));
      verifyNeverCall(verificationResponse);
    });
  });

  group('Using a method stub which passes a return argument to nSM,', () {
    test('nSM returns the dummy value during method stubbing', () {
      // Trigger method stubbing.
      final whenCall = when;
      final stubbedResponse = mock.returnsNonNullableString();

      // Under the pre-NNBD type system, this expectation is not interesting.
      // Under the NNBD type system, however, it is important that the second
      // argument passed to `noSuchMethod` in `returnsNonNullableString` is
      // returned by `noSuchMethod`, so that non-null values are can be returned
      // when necessary.
      expect(stubbedResponse, equals('Dummy'));
      whenCall(stubbedResponse).thenReturn('A');
    });

    test('nSM returns the dummy value during method call verification', () {
      when(mock.returnsNonNullableString()).thenReturn('A');

      // Make a real call.
      final realResponse = mock.returnsNonNullableString();

      // Under the pre-NNBD type system, this expectation is not interesting.
      // Under the NNBD type system, however, it is important that the second
      // argument passed to `noSuchMethod` in `returnsNonNullableString` is
      // _not_ returned by `noSuchMethod`; the canned response, `'A'`, should be
      // returned.
      expect(realResponse, equals('A'));

      // Trigger method call verification.
      final verifyCall = verify;
      final verificationResponse = mock.returnsNonNullableString();
      expect(verificationResponse, equals('Dummy'));
      verifyCall(verificationResponse);
    });

    test(
        'nSM returns the dummy value during method call verification, using '
        'verifyNever', () {
      // Trigger method call verification.
      final verifyNeverCall = verifyNever;
      final verificationResponse = mock.returnsNonNullableString();
      expect(verificationResponse, equals('Dummy'));
      verifyNeverCall(verificationResponse);
    });
  });
}
