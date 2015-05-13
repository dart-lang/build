import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

class RealClass {
  String methodWithoutArgs() => "Real";
  String methodWithNormalArgs(int x) => "Real";
  String methodWithPositionalArgs(int x, [int y]) => "Real";
  String methodWithNamedArgs(int x, {int y}) => "Real";
  String get getter => "Real";
  void set setter(String arg) {
    throw new StateError("I must be mocked");
  }
}

abstract class Foo {
  String bar();
}

abstract class AbstractFoo implements Foo {
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

void main() {
  RealClass mock;

  setUp(() {
    mock = new MockedClass();
  });

  group("spy", () {
    setUp(() {
      mock = spy(new MockedClass(), new RealClass());
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
    test("should mock method with argument matcher", () {
      when(mock.methodWithNormalArgs(argThat(greaterThan(100))))
          .thenReturn("A lot!");
      expect(mock.methodWithNormalArgs(100), isNull);
      expect(mock.methodWithNormalArgs(101), equals("A lot!"));
    });
    test("should mock method with any argument matcher", () {
      when(mock.methodWithNormalArgs(any)).thenReturn("A lot!");
      expect(mock.methodWithNormalArgs(100), equals("A lot!"));
      expect(mock.methodWithNormalArgs(101), equals("A lot!"));
    });
    test("should mock method with mix of argument matchers and real things",
        () {
      when(mock.methodWithPositionalArgs(argThat(greaterThan(100)), 17))
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
//    test("should n't mock toString", (){
//      when(mock.toString()).thenReturn("meow");
//      expect(mock.toString(), equals("meow"));
//    });
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
    test("should mock method with calculated result", () {
      when(mock.methodWithNormalArgs(any)).thenAnswer(
          (Invocation inv) => inv.positionalArguments[0].toString());
      expect(mock.methodWithNormalArgs(43), equals("43"));
      expect(mock.methodWithNormalArgs(42), equals("42"));
    });
    test("should return mock to make simple oneline mocks", () {
      RealClass mockWithSetup =
          when(new MockedClass().methodWithoutArgs()).thenReturn("oneline");
      expect(mockWithSetup.methodWithoutArgs(), equals("oneline"));
    });
    test("should use latest matching when definition", () {
      when(mock.methodWithoutArgs()).thenReturn("A");
      when(mock.methodWithoutArgs()).thenReturn("B");
      expect(mock.methodWithoutArgs(), equals("B"));
    });
    test("should mock method with calculated result", () {
      when(mock.methodWithNormalArgs(argThat(equals(43)))).thenReturn("43");
      when(mock.methodWithNormalArgs(argThat(equals(42)))).thenReturn("42");
      expect(mock.methodWithNormalArgs(43), equals("43"));
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
          "No matching calls. All calls: MockedClass.methodWithNormalArgs(42)",
          () {
        verify(mock.methodWithNormalArgs(43));
      });
      verify(mock.methodWithNormalArgs(42));
    });
    test("should mock method with positional args", () {
      mock.methodWithPositionalArgs(42, 17);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(42, 17)",
          () {
        verify(mock.methodWithPositionalArgs(42));
      });
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(42, 17)",
          () {
        verify(mock.methodWithPositionalArgs(42, 18));
      });
      verify(mock.methodWithPositionalArgs(42, 17));
    });
    test("should mock method with named args", () {
      mock.methodWithNamedArgs(42, y: 17);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNamedArgs(42, {y: 17})",
          () {
        verify(mock.methodWithNamedArgs(42));
      });
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNamedArgs(42, {y: 17})",
          () {
        verify(mock.methodWithNamedArgs(42, y: 18));
      });
      verify(mock.methodWithNamedArgs(42, y: 17));
    });
    test("should mock method with argument matcher", () {
      mock.methodWithNormalArgs(100);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithNormalArgs(100)",
          () {
        verify(mock.methodWithNormalArgs(argThat(greaterThan(100))));
      });
      verify(mock.methodWithNormalArgs(argThat(greaterThanOrEqualTo(100))));
    });
    test("should mock method with argument capturer", () {
      mock.methodWithNormalArgs(50);
      mock.methodWithNormalArgs(100);
      expect(verify(mock.methodWithNormalArgs(captureAny)).captured,
          equals([50, 100]));
    });
    test("should mock method with argument matcher and capturer", () {
      mock.methodWithNormalArgs(50);
      mock.methodWithNormalArgs(100);
      expect(verify(mock.methodWithNormalArgs(
          captureThat(greaterThan(75)))).captured.single, equals(100));
      expect(verify(mock
              .methodWithNormalArgs(captureThat(lessThan(75)))).captured.single,
          equals(50));
    });
    test("should mock method with mix of argument matchers and real things",
        () {
      mock.methodWithPositionalArgs(100, 17);
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(100, 17)",
          () {
        verify(mock.methodWithPositionalArgs(
            argThat(greaterThanOrEqualTo(100)), 18));
      });
      expectFail(
          "No matching calls. All calls: MockedClass.methodWithPositionalArgs(100, 17)",
          () {
        verify(mock.methodWithPositionalArgs(argThat(greaterThan(100)), 17));
      });
      verify(mock.methodWithPositionalArgs(
          argThat(greaterThanOrEqualTo(100)), 17));
    });
    test("should mock getter", () {
      mock.getter;
      verify(mock.getter);
    });
    test("should mock setter", () {
      mock.setter = "A";
      expectFail("No matching calls. All calls: MockedClass.setter==A", () {
        verify(mock.setter = "B");
      });
      verify(mock.setter = "A");
    });
  });
  group("verify() qualifies", () {
    group("unqualified as at least one", () {
      test("zero fails", () {
        expectFail("No matching calls.", () {
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
    group("counts calls", () {
      test("zero fails", () {
        expectFail("No matching calls.", () {
          verify(mock.methodWithoutArgs()).called(1);
        });
      });
      test("one passes", () {
        mock.methodWithoutArgs();
        verify(mock.methodWithoutArgs()).called(1);
      });
      test("more than one fails", () {
        mock.methodWithoutArgs();
        mock.methodWithoutArgs();
        expectFail("Expected: <1>\n  Actual: <2>\nUnexpected number of calls\n",
            () {
          verify(mock.methodWithoutArgs()).called(1);
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
            "No matching calls. All calls: [VERIFIED] MockedClass.methodWithoutArgs()",
            () {
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
      expect(verify(mock.methodWithNormalArgs(captureAny)).captured.single,
          equals(42));
    });
    test("should captureOut multiple arguments", () {
      mock.methodWithPositionalArgs(1, 2);
      expect(verify(
              mock.methodWithPositionalArgs(captureAny, captureAny)).captured,
          equals([1, 2]));
    });
    test("should captureOut with matching arguments", () {
      mock.methodWithPositionalArgs(1);
      mock.methodWithPositionalArgs(2, 3);
      expect(verify(
              mock.methodWithPositionalArgs(captureAny, captureAny)).captured,
          equals([2, 3]));
    });
    test("should captureOut multiple invocations", () {
      mock.methodWithNormalArgs(1);
      mock.methodWithNormalArgs(2);
      expect(verify(mock.methodWithNormalArgs(captureAny)).captured,
          equals([1, 2]));
    });
  });
}
