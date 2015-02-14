library source_gen.generator;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';

abstract class Generator {
  const Generator();

  Future<String> generate(Element element);
}

class InvalidGenerationSourceError {
  final String message;
  final String todo;

  InvalidGenerationSourceError(this.message, {String todo})
      : this.todo = todo == null ? '' : todo;
}
