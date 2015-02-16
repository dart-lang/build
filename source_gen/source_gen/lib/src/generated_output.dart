library source_gen.generated_output;

import 'dart:convert';

import 'package:analyzer/src/generated/element.dart';

import 'generator.dart';

class GeneratedOutput {
  final Element sourceMember;
  final String output;
  final Generator generator;
  final error;
  final StackTrace stackTrace;

  bool get isError => error != null;

  GeneratedOutput(this.sourceMember, this.generator, this.output)
      : error = null,
        stackTrace = null;

  GeneratedOutput.fromError(this.sourceMember, this.generator, Object error,
      [this.stackTrace])
      : this.output = _outputFromError(error),
        this.error = error;
}

String _outputFromError(Object error) {
  if (error == null) {
    throw new ArgumentError.notNull('error');
  }

  var buffer = new StringBuffer();

  _commentWithHeader(_errorHeader, error.toString(), buffer);

  if (error is InvalidGenerationSourceError && error.todo.isNotEmpty) {
    _commentWithHeader(_todoHeader, error.todo, buffer);
  }

  print(buffer.toString());

  return buffer.toString();
}

void _commentWithHeader(String header, String content, StringSink buffer) {
  var lines = const LineSplitter().convert(content);

  buffer.writeAll([_commentPrefix, header, lines.first]);
  buffer.writeln();

  var blankPrefix = ''.padLeft(header.length, ' ');
  for (var i = 1; i < lines.length; i++) {
    buffer.writeAll([_commentPrefix, blankPrefix, lines[i]]);
  }
}

const _commentPrefix = '// ';
const _errorHeader = 'Error: ';
const _todoHeader = 'TODO: ';
