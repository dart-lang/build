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
