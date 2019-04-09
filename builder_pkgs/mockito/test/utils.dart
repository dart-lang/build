import 'package:mockito/mockito.dart';

abstract class NsmForwardingSignal {
  void fn([int a]);
}

class MockNsmForwardingSignal extends Mock implements NsmForwardingSignal {}

bool assessNsmForwarding() {
  var signal = MockNsmForwardingSignal();
  signal.fn();
  try {
    verify(signal.fn(any));
    return true;
  } catch (_) {
    // The verify failed, because the default value of 7 was not passed to
    // noSuchMethod.
    verify(signal.fn());
    return false;
  }
}
