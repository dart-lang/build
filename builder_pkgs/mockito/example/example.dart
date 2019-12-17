// ignore_for_file: sdk_version_async_exported_from_core
// ignore_for_file: unawaited_futures
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Real class
class Cat {
  String sound() => 'Meow';
  bool eatFood(String food, {bool hungry}) => true;
  Future<void> chew() async => print('Chewing...');
  int walk(List<String> places) => 7;
  void sleep() {}
  void hunt(String place, String prey) {}
  int lives = 9;
}

// Mock class
class MockCat extends Mock implements Cat {}

// Fake class
class FakeCat extends Fake implements Cat {
  @override
  bool eatFood(String food, {bool hungry}) {
    print('Fake eat $food');
    return true;
  }
}

void main() {
  Cat cat;

  setUp(() {
    // Create mock object.
    cat = MockCat();
  });

  test("Let's verify some behaviour!", () {
    // Interact with the mock object.
    cat.sound();

    // Verify the interaction.
    verify(cat.sound());
  });

  test('How about some stubbing?', () {
    // Unstubbed methods return null.
    expect(cat.sound(), null);

    // Stub a method before interacting with it.
    when(cat.sound()).thenReturn('Purr');
    expect(cat.sound(), 'Purr');

    // You can call it again.
    expect(cat.sound(), 'Purr');

    // Let's change the stub.
    when(cat.sound()).thenReturn('Meow');
    expect(cat.sound(), 'Meow');

    // You can stub getters.
    when(cat.lives).thenReturn(9);
    expect(cat.lives, 9);

    // You can stub a method to throw.
    when(cat.lives).thenThrow(RangeError('Boo'));
    expect(() => cat.lives, throwsRangeError);

    // We can calculate a response at call time.
    var responses = ['Purr', 'Meow'];
    when(cat.sound()).thenAnswer((_) => responses.removeAt(0));
    expect(cat.sound(), 'Purr');
    expect(cat.sound(), 'Meow');
  });

  test('Argument matchers', () {
    // You can use plain arguments themselves
    when(cat.eatFood('fish')).thenReturn(true);

    // ... including collections
    when(cat.walk(['roof', 'tree'])).thenReturn(2);

    // ... or matchers
    when(cat.eatFood(argThat(startsWith('dry')))).thenReturn(false);

    // ... or mix aguments with matchers
    when(cat.eatFood(argThat(startsWith('dry')), hungry: true))
        .thenReturn(true);
    expect(cat.eatFood('fish'), isTrue);
    expect(cat.walk(['roof', 'tree']), equals(2));
    expect(cat.eatFood('dry food'), isFalse);
    expect(cat.eatFood('dry food', hungry: true), isTrue);

    // You can also verify using an argument matcher.
    verify(cat.eatFood('fish'));
    verify(cat.walk(['roof', 'tree']));
    verify(cat.eatFood(argThat(contains('food'))));

    // You can verify setters.
    cat.lives = 9;
    verify(cat.lives = 9);

    cat.hunt('backyard', null);
    verify(cat.hunt('backyard', null)); // OK: no arg matchers.

    cat.hunt('backyard', null);
    verify(cat.hunt(argThat(contains('yard')),
        argThat(isNull))); // OK: null is wrapped in an arg matcher.
  });

  test('Named arguments', () {
    // GOOD: argument matchers include their names.
    when(cat.eatFood(any, hungry: anyNamed('hungry'))).thenReturn(true);
    when(cat.eatFood(any, hungry: argThat(isNotNull, named: 'hungry')))
        .thenReturn(false);
    when(cat.eatFood(any, hungry: captureAnyNamed('hungry'))).thenReturn(false);
    when(cat.eatFood(any, hungry: captureThat(isNotNull, named: 'hungry')))
        .thenReturn(true);
  });

  test('Verifying exact number of invocations / at least x / never', () {
    cat.sound();
    cat.sound();
    // Exact number of invocations
    verify(cat.sound()).called(2);

    cat.sound();
    cat.sound();
    cat.sound();
    // Or using matcher
    verify(cat.sound()).called(greaterThan(1));

    // Or never called
    verifyNever(cat.eatFood(any));
  });

  test('Verification in order', () {
    cat.eatFood('Milk');
    cat.sound();
    cat.eatFood('Fish');
    verifyInOrder([cat.eatFood('Milk'), cat.sound(), cat.eatFood('Fish')]);
  });

  test('Making sure interaction(s) never happened on mock', () {
    verifyZeroInteractions(cat);
  });

  test('Finding redundant invocations', () {
    cat.sound();
    verify(cat.sound());
    verifyNoMoreInteractions(cat);
  });

  test('Capturing arguments for further assertions', () {
    // Simple capture:
    cat.eatFood('Fish');
    expect(verify(cat.eatFood(captureAny)).captured.single, 'Fish');

    // Capture multiple calls:
    cat.eatFood('Milk');
    cat.eatFood('Fish');
    expect(verify(cat.eatFood(captureAny)).captured, ['Milk', 'Fish']);

    // Conditional capture:
    cat.eatFood('Milk');
    cat.eatFood('Fish');
    expect(
        verify(cat.eatFood(captureThat(startsWith('F')))).captured, ['Fish']);
  });

  test('Waiting for an interaction', () async {
    Future<void> chewHelper(Cat cat) {
      return cat.chew();
    }

    // Waiting for a call.
    chewHelper(cat);
    await untilCalled(cat.chew()); // This completes when cat.chew() is called.

    // Waiting for a call that has already happened.
    cat.eatFood('Fish');
    await untilCalled(cat.eatFood(any)); // This completes immediately.
  });

  test('Fake class', () {
    // Create a new fake Cat at runtime.
    var cat = FakeCat();

    cat.eatFood('Milk'); // Prints 'Fake eat Milk'.
    expect(() => cat.sleep(), throwsUnimplementedError);
  });
}
