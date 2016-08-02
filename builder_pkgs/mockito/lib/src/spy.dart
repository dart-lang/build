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
