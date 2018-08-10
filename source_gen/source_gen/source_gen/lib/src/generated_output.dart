// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'generator.dart';

class GeneratedOutput {
  final String output;
  final Generator generator;
  final dynamic error;
  final StackTrace stackTrace;

  bool get isError => error != null;

  GeneratedOutput(this.generator, this.output)
      : error = null,
        stackTrace = null,
        assert(output != null),
        assert(output.isNotEmpty),
        // assuming length check is cheaper than simple string equality
        assert(output.length == output.trim().length);

  GeneratedOutput.fromError(this.generator, this.error, this.stackTrace)
      : this.output = _outputFromError(error);

  @override
  String toString() {
    var output = generator.toString();
    if (output.endsWith('Generator')) {
      return output;
    }
    return 'Generator: $output';
  }
}

String _outputFromError(Object error) {
  var buffer = StringBuffer();

  _commentWithHeader(_errorHeader, error.toString(), buffer);

  if (error is InvalidGenerationSourceError && error.todo.isNotEmpty) {
    _commentWithHeader(_todoHeader, error.todo, buffer);
  }

  return buffer.toString();
}

void _commentWithHeader(String header, String content, StringSink buffer) {
  var lines = const LineSplitter().convert(content);

  buffer.writeAll([_commentPrefix, header, lines.first]);
  buffer.writeln();

  var blankPrefix = ''.padLeft(header.length, ' ');
  for (var i = 1; i < lines.length; i++) {
    buffer.writeAll([_commentPrefix, blankPrefix, lines[i]]);
    buffer.writeln();
  }
}

const _commentPrefix = '// ';
const _errorHeader = 'Error: ';
const _todoHeader = 'TODO: ';
