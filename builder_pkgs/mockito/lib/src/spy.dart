// This file is intentionally separated from 'mock.dart' in order to avoid
// bringing in the mirrors dependency into mockito_no_mirrors.dart.
import 'dart:mirrors';

import 'mock.dart' show CannedResponse, setDefaultResponse;

@Deprecated(
  'Mockito is dropping support for spy(). Instead it is recommended to come '
  'up with a code-generation technique or just hand-coding a Stub object that '
  'forwards to a delegate. For example:\n\n'
  'class SpyAnimal implements Animal {\n'
  '  final Animal _delegate;\n'
  '  FakeAnimal(this._delegate);\n'
  '\n'
  '  @override\n'
  '  void eat() {\n'
  '    _delegate.eat();\n'
  '  }\n'
  '}'
)
dynamic spy(dynamic mock, dynamic spiedObject) {
  var mirror = reflect(spiedObject);
  setDefaultResponse(
      mock,
      () => new CannedResponse(null,
          (Invocation realInvocation) => mirror.delegate(realInvocation)));
  return mock;
}
