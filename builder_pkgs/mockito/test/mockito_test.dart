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

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:mockito/src/mock.dart'
    show resetMockitoState, throwOnMissingStub;
import 'package:test/test.dart';

class RealClass {
  RealClass innerObj;
  String methodWithoutArgs() => "Real";
  String methodWithNormalArgs(int x) => "Real";
  String methodWithListArgs(List<int> x) => "Real";
  String methodWithPositionalArgs(int x, [int y]) => "Real";
  String methodWithNamedArgs(int x, {int y}) => "Real";
  String methodWithTwoNamedArgs(int x, {int y, int z}) => "Real";
  String methodWithObjArgs(RealClass x) => "Real";
  Future<String> methodReturningFuture() => new Future.value("Real");
  Stream<String> methodReturningStream() => new Stream.fromIterable(["Real"]);
  // "SpecialArgs" here means type-parameterized args. But that makes for a long
  // method name.
  String typeParameterizedFn(List<int> w, List<int> x,
          [List<int> y, List<int> z]) =>
      "Real";
  // "SpecialNamedArgs" here means type-parameterized, named args. But that
  // makes for a long method name.
  String typeParameterizedNamedFn(List<int> w, List<int> x,
          {List<int> y, List<int> z}) =>
      "Real";
  String get getter => "Real";
  set setter(String arg) {
    throw new StateError("I must be mocked");
  }
}

class CallMethodsEvent {}

/// Listens on a stream and upon any event calls all methods in [RealClass].
class RealClassController {
  final RealClass _realClass;

  RealClassController(
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
      ..methodWithObjArgs(new RealClass())
      ..typeParameterizedFn([1, 2], [3, 4], [5, 6], [7, 8])
      ..typeParameterizedNamedFn([1, 2], [3, 4], y: [5, 6], z: [7, 8])
      ..getter
      ..setter = "A";
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

class MockedClass extends Mock implements RealClass {}

expectFail(String expectedMessage, expectedToFail()) {
  try {
    expectedToFail();
    fail("It was expected to fail!");
  } catch (e) {
    if (!(e is TestFailure)) {
      throw e;
    } else {
      if (expectedMessage != e.message) {
        throw new TestFailure("Failed, but with wrong message: ${e.message}");
      }
    }
  }
}

String noMatchingCallsFooter = "(If you called `verify(...).called(0);`, "
    "please instead use `verifyNever(...);`.)";

void main() {
  MockedClass mock;

  setUp(() {
    mock = new MockedClass();
  });

  tearDown(() {
    // In some of the tests that expect an Error to be thrown, Mockito's
    // global state can become invalid. Reset it.
    resetMockitoState();
  });

  group("mixin support", () {
    test("should work", () {
      var foo = new MockFoo();
      when(foo.baz()).thenReturn('baz');
      expect(foo.bar(), 'baz');
    });
  });

  group("when()", () {
    test("should mock method without args", () {
      when(mock.methodWithoutArgs()).thenReturn("A");
      expect(mock.methodWithoutArgs(), equals("A"));
    });

    test("should mock method with normal args", () {
      when(mock.methodWithNormalArgs(42)).thenReturn("Ultimate Answer");
      expect(mock.methodWithNormalArgs(43), isNull);
      expect(mock.methodWithNormalArgs(42), equals("Ultimate Answer"));
    });

    test("should mock method with mock args", () {
      var m1 = new MockedClass();
      when(mock.methodWithObjArgs(m1)).thenReturn("Ultimate Answer");
      expect(mock.methodWithObjArgs(new MockedClass()), isNull);
      expect(mock.methodWithObjArgs(m1), equals("Ultimate Answer"));
    });

    test("should mock method with positional args", () {
      when(mock.methodWithPositionalArgs(42, 17)).thenReturn("Answer and...");
      expect(mock.methodWithPositionalArgs(42), isNull);
      expect(mock.methodWithPositionalArgs(42, 18), isNull);
      expect(mock.methodWithPositionalArgs(42, 17), equals("Answer and..."));
    });

    test("should mock method with named args", () {
      when(mock.methodWithNamedArgs(42, y: 17)).thenReturn("Why answer?");
      expect(mock.methodWithNamedArgs(42), isNull);
      expect(mock.methodWithNamedArgs(42, y: 18), isNull);
      expect(mock.methodWithNamedArgs(42, y: 17), equals("Why answer?"));
    });

    test("should mock method with List args", () {
      when(mock.methodWithListArgs([42])).thenReturn("Ultimate answer");
      expect(mock.methodWithListArgs([43]), isNull);
      expect(mock.methodWithListArgs([42]), equals("Ultimate answer"));
    });

    test("should mock method with argument matcher", () {
      when(mock.methodWithNormalArgs(typed(argThat(greaterThan(100)))))
          .thenReturn("A lot!");
      expect(mock.methodWithNormalArgs(100), isNull);
      expect(mock.methodWithNormalArgs(101), equals("A lot!"));
    });

    test("should mock method with any argument matcher", () {
      when(mock.methodWithNormalArgs(typed(any))).thenReturn("A lot!");
      expect(mock.methodWithNormalArgs(100), equals("A lot!"));
      expect(mock.methodWithNormalArgs(101), equals("A lot!"));
    });

    test("should mock method with any list argument matcher", () {
      when(mock.methodWithListArgs(typed(any))).thenReturn("A lot!");
      expect(mock.methodWithListArgs([42]), equals("A lot!"));
      expect(mock.methodWithListArgs([43]), equals("A lot!"));
    });

    test("should mock method with multiple named args and matchers", () {
      when(mock.methodWithTwoNamedArgs(any, y: anyNamed('y')))
          .thenReturn("x y");
      when(mock.methodWithTwoNamedArgs(any, z: anyNamed('z')))
          .thenReturn("x z");
      expect(mock.methodWithTwoNamedArgs(42), isNull);
      expect(mock.methodWithTwoNamedArgs(42, y: 18), equals("x y"));
      expect(mock.methodWithTwoNamedArgs(42, z: 17), equals("x z"));
      expect(mock.methodWithTwoNamedArgs(42, y: 18, z: 17), isNull);
      when(mock.methodWithTwoNamedArgs(any, y: anyNamed('y'), z: anyNamed('z')))
          .thenReturn("x y z");
      expect(mock.methodWithTwoNamedArgs(42, y: 18, z: 17), equals("x y z"));
    });

    test("should mock method with mix of argument matchers and real things",
        () {
      when(mock.methodWithPositionalArgs(typed(argThat(greaterThan(100))), 17))
          .thenReturn("A lot with 17");
      expect(mock.methodWithPositionalArgs(100, 17), isNull);
      expect(mock.methodWithPositionalArgs(101, 18), isNull);
      expect(mock.methodWithPositionalArgs(101, 17), equals("A lot with 17"));
    });

    test("should mock getter", () {
      when(mock.getter).thenReturn("A");
      expect(mock.getter, equals("A"));
    });

    test("should mock hashCode", () {
      named(mock, hashCode: 42);
      expect(mock.hashCode, equals(42));
    });

    test("should have hashCode when it is not mocked", () {
      expect(mock.hashCode, isNotNull);
    });

    test("should have default toString when it is not mocked", () {
      expect(mock.toString(), equals("MockedClass"));
    });

    test("should have toString as name when it is not mocked", () {
      named(mock, name: "Cat");
      expect(mock.toString(), equals("Cat"));
    });

    test("should mock equals between mocks when givenHashCode is equals", () {
      var anotherMock = named(new MockedClass(), hashCode: 42);
      named(mock, hashCode: 42);
      expect(mock == anotherMock, isTrue);
    });

    test("should use identical equality between it is not mocked", () {
      var anotherMock = new MockedClass();
      expect(mock == anotherMock, isFalse);
      expect(mock == mock, isTrue);
    });

    //no need to mock setter, except if we will have spies later...
    test("should mock method with thrown result", () {
      when(mock.methodWithNormalArgs(typed(any)))
          .thenThrow(new StateError('Boo'));
      expect(() => mock.methodWithNormalArgs(42), throwsStateError);
    });

    test("should mock method with calculated result", () {
      when(mock.methodWithNormalArgs(typed(any))).thenAnswer(
          (Invocation inv) => inv.positionalArguments[0].toString());
      expect(mock.methodWithNormalArgs(43), equals("43"));
      expect(mock.methodWithNormalArgs(42), equals("42"));
    });

    test("should return mock to make simple oneline mocks", () {
      RealClass mockWithSetup = new MockedClass();
      when(mockWithSetup.methodWithoutArgs()).thenReturn("oneline");
      expect(mockWithSetup.methodWithoutArgs(), equals("oneline"));
    });

    test("should use latest matching when definition", () {
      when(mock.methodWithoutArgs()).thenReturn("A");
      when(mock.methodWithoutArgs()).thenReturn("B");
      expect(mock.methodWithoutArgs(), equals("B"));
    });

    test("should mock method with calculated result", () {
      when(mock.methodWithNormalArgs(typed(argThat(equals(43)))))
          .thenReturn("43");
      when(mock.methodWithNormalArgs(typed(argThat(equals(42)))))
          .thenReturn("42");
      expect(mock.methodWithNormalArgs(43), equals("43"));
    });

    // Error path tests.
    test("should throw if `when` is called while stubbing", () {
      expect(() {
        var responseHelper = () {
          var mock2 = new MockedClass();
          when(mock2.getter).thenReturn("A");
          return mock2;
        };
        when(mock.innerObj).thenReturn(responseHelper());
      }, throwsStateError);
    });

    test("should throw if `null` is passed alongside matchers", () {
      expect(() {
        when(mock.methodWithPositionalArgs(argThat(equals(42)), null))
            .thenReturn("99");
      }, throwsArgumentError);

      // but doesn't ruin later calls.
      when(mock.methodWithNormalArgs(43)).thenReturn("43");
    });

    test("thenReturn throws if provided Future", () {
      expect(
          () => when(mock.methodReturningFuture())
              .thenReturn(new Future.value("stub")),
          throwsArgumentError);
    });

    test("thenReturn throws if provided Stream", () {
      expect(
          () => when(mock.methodReturningStream())
              .thenReturn(new Stream.fromIterable(["stub"])),
          throwsArgumentError);
    });

    test("thenAnswer supports stubbing method returning a Future", () async {
      when(mock.methodReturningFuture())
          .thenAnswer((_) => new Future.value("stub"));

      expect(await mock.methodReturningFuture(), "stub");
    });

    test("thenAnswer supports stubbing method returning a Stream", () async {
      when(mock.methodReturningStream())
          .thenAnswer((_) => new Stream.fromIterable(["stub"]));

      expect(await mock.methodReturningStream().toList(), ["stub"]);
    });

    test("should throw if `null` is passed as a named arg", () {
      expect(() {
        when(mock.methodWithNamedArgs(argThat(equals(42)), y: null))
            .thenReturn("99");
      }, throwsArgumentError);
    });

    test("should throw if named matcher is passed as a positional arg", () {
      expect(() {
        when(mock.methodWithNamedArgs(argThat(equals(42), named: "y")))
            .thenReturn("99");
      }, throwsArgumentError);
    });

    test("should throw if named matcher is passed as the wrong name", () {
      expect(() {
        when(mock.methodWithNamedArgs(argThat(equals(42)), y: anyNamed("z")))
            .thenReturn("99");
      }, throwsArgumentError);
    });
  });

  group("untilCalled", () {
    StreamController<CallMethodsEvent> streamController =
        new StreamController.broadcast();

    group("on methods already called", () {
      test("waits for method without args", () async {
        mock.methodWithoutArgs();

        await untilCalled(mock.methodWithoutArgs());

        verify(mock.methodWithoutArgs()).called(1);
      });

      test("waits for method with normal args", () async {
        mock.methodWithNormalArgs(1);

        await untilCalled(mock.methodWithNormalArgs(typed(any)));

        verify(mock.methodWithNormalArgs(typed(any))).called(1);
      });

      test("waits for method with list args", () async {
        mock.methodWithListArgs([1]);

        await untilCalled(mock.methodWithListArgs(typed(any)));

        verify(mock.methodWithListArgs(typed(any))).called(1);
      });

      test("waits for method with positional args", () async {
        mock.methodWithPositionalArgs(1, 2);

        await untilCalled(
            mock.methodWithPositionalArgs(typed(any), typed(any)));

        verify(mock.methodWithPositionalArgs(typed(any), typed(any))).called(1);
      });

      test("waits for method with named args", () async {
        mock.methodWithNamedArgs(1, y: 2);

        await untilCalled(mock.methodWithNamedArgs(any, y: anyNamed('y')));

        verify(mock.methodWithNamedArgs(any, y: anyNamed('y'))).called(1);
      });

      test("waits for method with two named args", () async {
        mock.methodWithTwoNamedArgs(1, y: 2, z: 3);

        await untilCalled(mock.methodWithTwoNamedArgs(any,
            y: anyNamed('y'), z: anyNamed('z')));

        verify(mock.methodWithTwoNamedArgs(any,
                y: anyNamed('y'), z: anyNamed('z')))
            .called(1);
      });

      test("waits for method with obj args", () async {
        mock.methodWithObjArgs(new RealClass());

        await untilCalled(mock.methodWithObjArgs(typed(any)));

        verify(mock.methodWithObjArgs(typed(any))).called(1);
      });

      test("waits for function with positional parameters", () async {
        mock.typeParameterizedFn([1, 2], [3, 4], [5, 6], [7, 8]);

        await untilCalled(mock.typeParameterizedFn(
            typed(any), typed(any), typed(any), typed(any)));

        verify(mock.typeParameterizedFn(
                typed(any), typed(any), typed(any), typed(any)))
            .called(1);
      });

      test("waits for function with named parameters", () async {
        mock.typeParameterizedNamedFn([1, 2], [3, 4], y: [5, 6], z: [7, 8]);

        await untilCalled(mock.typeParameterizedNamedFn(any, any,
            y: anyNamed('y'), z: anyNamed('z')));

        verify(mock.typeParameterizedNamedFn(any, any,
                y: anyNamed('y'), z: anyNamed('z')))
            .called(1);
      });

      test("waits for getter", () async {
        mock.getter;

        await untilCalled(mock.getter);

        verify(mock.getter).called(1);
      });

      test("waits for setter", () async {
        mock.setter = "A";

        await untilCalled(mock.setter = "A");

        verify(mock.setter = "A").called(1);
      });
    });

    group("on methods not yet called", () {
      setUp(() {
        new RealClassController(mock, streamController);
      });

      test("waits for method without args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithoutArgs());

        await untilCalled(mock.methodWithoutArgs());

        verify(mock.methodWithoutArgs()).called(1);
      });

      test("waits for method with normal args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithNormalArgs(typed(any)));

        await untilCalled(mock.methodWithNormalArgs(typed(any)));

        verify(mock.methodWithNormalArgs(typed(any))).called(1);
      });

      test("waits for method with list args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithListArgs(typed(any)));

        await untilCalled(mock.methodWithListArgs(typed(any)));

        verify(mock.methodWithListArgs(typed(any))).called(1);
      });

      test("waits for method with positional args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithPositionalArgs(typed(any), typed(any)));

        await untilCalled(
            mock.methodWithPositionalArgs(typed(any), typed(any)));

        verify(mock.methodWithPositionalArgs(typed(any), typed(any))).called(1);
      });

      test("waits for method with named args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithNamedArgs(any, y: anyNamed('y')));

        await untilCalled(mock.methodWithNamedArgs(any, y: anyNamed('y')));

        verify(mock.methodWithNamedArgs(any, y: anyNamed('y'))).called(1);
      });

      test("waits for method with two named args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithTwoNamedArgs(any,
            y: anyNamed('y'), z: anyNamed('z')));

        await untilCalled(mock.methodWithTwoNamedArgs(any,
            y: anyNamed('y'), z: anyNamed('z')));

        verify(mock.methodWithTwoNamedArgs(any,
                y: anyNamed('y'), z: anyNamed('z')))
            .called(1);
      });

      test("waits for method with obj args", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.methodWithObjArgs(typed(any)));

        await untilCalled(mock.methodWithObjArgs(typed(any)));

        verify(mock.methodWithObjArgs(typed(any))).called(1);
      });

      test("waits for function with positional parameters", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.typeParameterizedFn(
            typed(any), typed(any), typed(any), typed(any)));

        await untilCalled(mock.typeParameterizedFn(
            typed(any), typed(any), typed(any), typed(any)));

        verify(mock.typeParameterizedFn(
                typed(any), typed(any), typed(any), typed(any)))
            .called(1);
      });

      test("waits for function with named parameters", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.typeParameterizedNamedFn(any, any,
            y: anyNamed('y'), z: anyNamed('z')));

        await untilCalled(mock.typeParameterizedNamedFn(any, any,
            y: anyNamed('y'), z: anyNamed('z')));

        verify(mock.typeParameterizedNamedFn(any, any,
                y: anyNamed('y'), z: anyNamed('z')))
            .called(1);
      });

      test("waits for getter", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.getter);

        await untilCalled(mock.getter);

        verify(mock.getter).called(1);
      });

      test("waits for setter", () async {
        streamController.add(new CallMethodsEvent());
        verifyNever(mock.setter = "A");

        await untilCalled(mock.setter = "A");

        verify(mock.setter = "A").called(1);
      });
    });
  });

  group("verify()", () {
    test("should verify method without args", () {
      mock.methodWithoutArgs();
      verify(mock.methodWithoutArgs());
    });

    test("should verify method with normal args", () {
      mock.methodWithNormalArgs(42);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNormalArgs(42)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithNormalArgs(43));
      });
      verify(mock.methodWithNormalArgs(42));
    });

    test("should mock method with positional args", () {
      mock.methodWithPositionalArgs(42, 17);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(42, 17)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithPositionalArgs(42));
      });
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(42, 17)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithPositionalArgs(42, 18));
      });
      verify(mock.methodWithPositionalArgs(42, 17));
    });

    test("should mock method with named args", () {
      mock.methodWithNamedArgs(42, y: 17);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNamedArgs(42, {y: 17})\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithNamedArgs(42));
      });
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNamedArgs(42, {y: 17})\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithNamedArgs(42, y: 18));
      });
      verify(mock.methodWithNamedArgs(42, y: 17));
    });

    test("should mock method with mock args", () {
      var m1 = named(new MockedClass(), name: "m1");
      mock.methodWithObjArgs(m1);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithObjArgs(m1)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithObjArgs(new MockedClass()));
      });
      verify(mock.methodWithObjArgs(m1));
    });

    test("should mock method with list args", () {
      mock.methodWithListArgs([42]);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithListArgs([42])\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithListArgs([43]));
      });
      verify(mock.methodWithListArgs([42]));
    });

    test("should mock method with argument matcher", () {
      mock.methodWithNormalArgs(100);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNormalArgs(100)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithNormalArgs(typed(argThat(greaterThan(100)))));
      });
      verify(
          mock.methodWithNormalArgs(typed(argThat(greaterThanOrEqualTo(100)))));
    });

    test("should mock method with argument capturer", () {
      mock.methodWithNormalArgs(50);
      mock.methodWithNormalArgs(100);
      expect(verify(mock.methodWithNormalArgs(typed(captureAny))).captured,
          equals([50, 100]));
    });

    test("should mock method with argument matcher and capturer", () {
      mock.methodWithNormalArgs(50);
      mock.methodWithNormalArgs(100);
      expect(
          verify(mock.methodWithNormalArgs(typed(captureThat(greaterThan(75)))))
              .captured
              .single,
          equals(100));
      expect(
          verify(mock.methodWithNormalArgs(typed(captureThat(lessThan(75)))))
              .captured
              .single,
          equals(50));
    });

    test("should mock method with mix of argument matchers and real things",
        () {
      mock.methodWithPositionalArgs(100, 17);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(100, 17)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithPositionalArgs(
            typed(argThat(greaterThanOrEqualTo(100))), 18));
      });
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(100, 17)\n"
          "$noMatchingCallsFooter", () {
        verify(mock.methodWithPositionalArgs(
            typed(argThat(greaterThan(100))), 17));
      });
      verify(mock.methodWithPositionalArgs(
          typed(argThat(greaterThanOrEqualTo(100))), 17));
    });

    test("should mock getter", () {
      mock.getter;
      verify(mock.getter);
    });

    test("should mock setter", () {
      mock.setter = "A";
      expectFail(
          "No matching calls. All calls: MockedClass.setter==A\n"
          "$noMatchingCallsFooter", () {
        verify(mock.setter = "B");
      });
      verify(mock.setter = "A");
    });

    test("should throw meaningful errors when verification is interrupted", () {
      var badHelper = () => throw 'boo';
      try {
        verify(mock.methodWithNamedArgs(42, y: badHelper()));
        fail("verify call was expected to throw!");
      } catch (_) {}
      // At this point, verification was interrupted, so
      // `_verificationInProgress` is still `true`. Calling mock methods below
      // adds items to `_verifyCalls`.
      mock.methodWithNamedArgs(42, y: 17);
      mock.methodWithNamedArgs(42, y: 17);
      try {
        verify(mock.methodWithNamedArgs(42, y: 17));
        fail("verify call was expected to throw!");
      } catch (e) {
        expect(e, new isInstanceOf<StateError>());
        expect(
            e.message,
            contains(
                "Verification appears to be in progress. 2 verify calls have been stored."));
      }
    });
  });

  group("verify() qualifies", () {
    group("unqualified as at least one", () {
      test("zero fails", () {
        expectFail(
            "No matching calls (actually, no calls at all).\n"
            "$noMatchingCallsFooter", () {
          verify(mock.methodWithoutArgs());
        });
      });

      test("one passes", () {
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs());
      });

      test("more than one passes", () {
        mock.methodWithoutArgs();
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs());
      });
    });

    group("expecting one call", () {
      test("zero actual calls fails", () {
        expectFail(
            "No matching calls (actually, no calls at all).\n"
            "$noMatchingCallsFooter", () {
          verify(mock.methodWithoutArgs()).called(1);
        });
      });

      test("one actual call passes", () {
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs()).called(1);
      });

      test("more than one actual call fails", () {
        mock.methodWithoutArgs();
        mock.methodWithoutArgs();
        expectFail("Expected: <1>\n  Actual: <2>\nUnexpected number of calls\n",
            () {
          verify(mock.methodWithoutArgs()).called(1);
        });
      });
    });

    group("expecting more than two calls", () {
      test("zero actual calls fails", () {
        expectFail(
            "No matching calls (actually, no calls at all).\n"
            "$noMatchingCallsFooter", () {
          verify(mock.methodWithoutArgs()).called(greaterThan(2));
        });
      });

      test("one actual call fails", () {
        mock.methodWithoutArgs();
        expectFail(
            "Expected: a value greater than <2>\n"
            "  Actual: <1>\n"
            "   Which: is not a value greater than <2>\n"
            "Unexpected number of calls\n", () {
          verify(mock.methodWithoutArgs()).called(greaterThan(2));
        });
      });

      test("three actual calls passes", () {
        mock.methodWithoutArgs();
        mock.methodWithoutArgs();
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs()).called(greaterThan(2));
      });
    });

    group("expecting zero calls", () {
      test("zero actual calls passes", () {
        expectFail(
            "No matching calls (actually, no calls at all).\n"
            "$noMatchingCallsFooter", () {
          verify(mock.methodWithoutArgs()).called(0);
        });
      });

      test("one actual call fails", () {
        mock.methodWithoutArgs();
        expectFail(
            "Expected: <0>\n"
            "  Actual: <1>\n"
            "Unexpected number of calls\n", () {
          verify(mock.methodWithoutArgs()).called(0);
        });
      });
    });

    group("verifyNever", () {
      test("zero passes", () {
        verifyNever(mock.methodWithoutArgs());
      });

      test("one fails", () {
        mock.methodWithoutArgs();
        expectFail(
            "Unexpected calls. All calls: MockedClass.methodWithoutArgs()", () {
          verifyNever(mock.methodWithoutArgs());
        });
      });
    });

    group("doesn't count already verified again", () {
      test("fail case", () {
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs());
        expectFail(
            "No matching calls. All calls: [VERIFIED] MockedClass.methodWithoutArgs()\n"
            "$noMatchingCallsFooter", () {
          verify(mock.methodWithoutArgs());
        });
      });

      test("pass case", () {
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs());
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs());
      });
    });
  });

  group("verifyZeroInteractions()", () {
    test("never touched pass", () {
      verifyZeroInteractions(mock);
    });

    test("any touch fails", () {
      mock.methodWithoutArgs();
      expectFail(
          "No interaction expected, but following found: MockedClass.methodWithoutArgs()",
          () {
        verifyZeroInteractions(mock);
      });
    });

    test("verifired call fails", () {
      mock.methodWithoutArgs();
      verify(mock.methodWithoutArgs());
      expectFail(
          "No interaction expected, but following found: [VERIFIED] MockedClass.methodWithoutArgs()",
          () {
        verifyZeroInteractions(mock);
      });
    });
  });

  group("verifyNoMoreInteractions()", () {
    test("never touched pass", () {
      verifyNoMoreInteractions(mock);
    });

    test("any unverified touch fails", () {
      mock.methodWithoutArgs();
      expectFail(
          "No more calls expected, but following found: MockedClass.methodWithoutArgs()",
          () {
        verifyNoMoreInteractions(mock);
      });
    });

    test("verified touch passes", () {
      mock.methodWithoutArgs();
      verify(mock.methodWithoutArgs());
      verifyNoMoreInteractions(mock);
    });

    test("throws if given a real object", () {
      expect(
          () => verifyNoMoreInteractions(new RealClass()), throwsArgumentError);
    });
  });

  group("verifyInOrder()", () {
    test("right order passes", () {
      mock.methodWithoutArgs();
      mock.getter;
      verifyInOrder([mock.methodWithoutArgs(), mock.getter]);
    });

    test("wrong order fails", () {
      mock.methodWithoutArgs();
      mock.getter;
      expectFail(
          "Matching call #1 not found. All calls: MockedClass.methodWithoutArgs(), MockedClass.getter",
          () {
        verifyInOrder([mock.getter, mock.methodWithoutArgs()]);
      });
    });

    test("uncomplete fails", () {
      mock.methodWithoutArgs();
      expectFail(
          "Matching call #1 not found. All calls: MockedClass.methodWithoutArgs()",
          () {
        verifyInOrder([mock.methodWithoutArgs(), mock.getter]);
      });
    });

    test("methods can be called again and again", () {
      mock.methodWithoutArgs();
      mock.getter;
      mock.methodWithoutArgs();
      verifyInOrder(
          [mock.methodWithoutArgs(), mock.getter, mock.methodWithoutArgs()]);
    });

    test("methods can be called again and again - fail case", () {
      mock.methodWithoutArgs();
      mock.methodWithoutArgs();
      mock.getter;
      expectFail(
          "Matching call #2 not found. All calls: MockedClass.methodWithoutArgs(), MockedClass.methodWithoutArgs(), MockedClass.getter",
          () {
        verifyInOrder(
            [mock.methodWithoutArgs(), mock.getter, mock.methodWithoutArgs()]);
      });
    });
  });

  group("capture", () {
    test("capture should work as captureOut", () {
      mock.methodWithNormalArgs(42);
      expect(
          verify(mock.methodWithNormalArgs(typed(captureAny))).captured.single,
          equals(42));
    });

    test("should captureOut list arguments", () {
      mock.methodWithListArgs([42]);
      expect(verify(mock.methodWithListArgs(typed(captureAny))).captured.single,
          equals([42]));
    });

    test("should captureOut multiple arguments", () {
      mock.methodWithPositionalArgs(1, 2);
      expect(
          verify(mock.methodWithPositionalArgs(
                  typed(captureAny), typed(captureAny)))
              .captured,
          equals([1, 2]));
    });

    test("should captureOut with matching arguments", () {
      mock.methodWithPositionalArgs(1);
      mock.methodWithPositionalArgs(2, 3);
      expect(
          verify(mock.methodWithPositionalArgs(
                  typed(captureAny), typed(captureAny)))
              .captured,
          equals([2, 3]));
    });

    test("should captureOut multiple invocations", () {
      mock.methodWithNormalArgs(1);
      mock.methodWithNormalArgs(2);
      expect(verify(mock.methodWithNormalArgs(typed(captureAny))).captured,
          equals([1, 2]));
    });
  });

  group("throwOnMissingStub", () {
    test("should throw when a mock was called without a matching stub", () {
      throwOnMissingStub(mock);
      when(mock.methodWithNormalArgs(42)).thenReturn("Ultimate Answer");
      expect(
        () => (mock).methodWithoutArgs(),
        throwsNoSuchMethodError,
      );
    });

    test("should not throw when a mock was called with a matching stub", () {
      throwOnMissingStub(mock);
      when(mock.methodWithoutArgs()).thenReturn("A");
      expect(() => mock.methodWithoutArgs(), returnsNormally);
    });
  });
}
