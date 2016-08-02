// This file is intentionally separated from 'mock.dart' in order to avoid
// bringing in the mirrors dependency into mockito_no_mirrors.dart.
import 'dart:mirrors';

import 'mock.dart' show CannedResponse, setDefaultResponse;

dynamic spy(dynamic mock, dynamic spiedObject) {
  var mirror = reflect(spiedObject);
  setDefaultResponse(
      mock,
      () => new CannedResponse(null,
          (Invocation realInvocation) => mirror.delegate(realInvocation)));
  return mock;
}
