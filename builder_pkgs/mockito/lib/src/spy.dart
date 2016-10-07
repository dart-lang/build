// This file is intentionally separated from 'mock.dart' in order to avoid
// bringing in the mirrors dependency into mockito.dart.
import 'dart:mirrors';

import 'mock.dart' show CannedResponse, Mock, setDefaultResponse;

/// Sets the default response of [mock] to be delegated to [spyOn].
///
/// __Example use__:
///     var mockAnimal = new MockAnimal();
///     var realAnimal = new RealAnimal();
///     spy(mockAnimal, realAnimal);
/*=E*/ spy/*<E>*/(Mock mock, Object /*=E*/ spyOn) {
  var mirror = reflect(spyOn);
  setDefaultResponse(
      mock,
      () => new CannedResponse(null,
          (Invocation realInvocation) => mirror.delegate(realInvocation)));
  return mock;
}
