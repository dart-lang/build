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
import 'package:test/test.dart';

import 'utils.dart';

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
  String get getter => "Real";
  set setter(String arg) {
    throw new StateError("I must be mocked");
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

  var isNsmForwarding = assessNsmForwarding();

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
      if (isNsmForwarding)
        expect(mock.methodWithTwoNamedArgs(42), "x z");
      else
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

    test("should throw if named matcher is passed as the wrong name", () {
      expect(() {
        when(mock.methodWithNamedArgs(argThat(equals(42)), y: anyNamed("z")))
            .thenReturn("99");
      }, throwsArgumentError);
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
