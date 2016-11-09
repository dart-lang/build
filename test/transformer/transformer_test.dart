// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';

import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:transformer_test/utils.dart';

import '../common/common.dart' hide testPhases;

void main() {
  var singleCopyTransformer = new BuilderTransformer(new CopyBuilder());
  var multiCopyTransformer =
      new BuilderTransformer(new CopyBuilder(numCopies: 2));
  var singleAndMultiCopyTransformer = new BuilderTransformer(
      new MultiplexingBuilder(
          [new CopyBuilder(), new CopyBuilder(numCopies: 2)]));

  testPhases('single builder, single output', [
    [singleCopyTransformer],
  ], {
    'a|web/a.txt': 'hello',
  }, {
    'a|web/a.txt.copy': 'hello',
  });

  testPhases('single builder, multiple outputs', [
    [multiCopyTransformer],
  ], {
    'a|web/a.txt': 'hello',
  }, {
    'a|web/a.txt.copy.0': 'hello',
    'a|web/a.txt.copy.1': 'hello',
  });

  testPhases('multiple builders, different outputs', [
    [singleAndMultiCopyTransformer],
  ], {
    'a|web/a.txt': 'hello',
  }, {
    'a|web/a.txt.copy': 'hello',
    'a|web/a.txt.copy.0': 'hello',
    'a|web/a.txt.copy.1': 'hello',
  });

  testPhases('multiple builders, same outputs', [
    [
      new BuilderTransformer(
          new MultiplexingBuilder([new CopyBuilder(), new CopyBuilder()]))
    ],
  ], {
    'a|web/a.txt': 'hello',
  }, {}, messages: [
    _fileExistsError('CopyBuilder', ['a|web/a.txt.copy']),
  ]);

  testPhases('multiple phases', [
    [singleCopyTransformer],
    [multiCopyTransformer],
  ], {
    'a|web/a.txt': 'hello',
  }, {
    'a|web/a.txt.copy': 'hello',
    'a|web/a.txt.copy.0': 'hello',
    'a|web/a.txt.copy.1': 'hello',
    'a|web/a.txt.copy.copy.0': 'hello',
    'a|web/a.txt.copy.copy.1': 'hello',
  });

  testPhases('multiple transformers in the same phase', [
    [singleCopyTransformer, multiCopyTransformer],
  ], {
    'a|web/a.txt': 'hello',
  }, {
    'a|web/a.txt.copy': 'hello',
    'a|web/a.txt.copy.0': 'hello',
    'a|web/a.txt.copy.1': 'hello',
  });

  testPhases(
      'cant overwrite files',
      [
        [singleCopyTransformer]
      ],
      {'a|web/a.txt': 'hello', 'a|web/a.txt.copy': 'hello'},
      {},
      messages: [
        _fileExistsError("CopyBuilder", ["a|web/a.txt.copy"]),
      ],
      expectBarbackErrors: true);

  // Gives a barback error only, we can't detect this situation.
  testPhases(
      'builders in the same phase can\'t output the same file',
      [
        [singleCopyTransformer, new BuilderTransformer(new CopyBuilder())]
      ],
      {
        'a|web/a.txt': 'hello',
      },
      {'a|web/a.txt.copy': 'hello'},
      expectBarbackErrors: true);

  testPhases(
      'builders in separate phases can\'t output the same file',
      [
        [singleCopyTransformer],
        [singleCopyTransformer],
      ],
      {'a|web/a.txt': 'hello'},
      {'a|web/a.txt.copy': 'hello'},
      messages: [
        _fileExistsError("CopyBuilder", ["a|web/a.txt.copy"]),
      ],
      expectBarbackErrors: true);

  testPhases('loggers log errors', [
    [new BuilderTransformer(new LoggingCopyBuilder())],
  ], {
    'a|web/a.txt': 'a',
    'a|web/b.txt': 'b',
  }, {}, messages: [
    allOf(startsWith('warning: Warning!'), contains('SomeError'),
        contains('LoggingCopyBuilder.build')),
    allOf(startsWith('error: Error!'), contains('SomeError'),
        contains('LoggingCopyBuilder.build')),
    allOf(startsWith('warning: Warning!'), contains('SomeError'),
        contains('LoggingCopyBuilder.build')),
    allOf(startsWith('error: Error!'), contains('SomeError'),
        contains('LoggingCopyBuilder.build')),
  ]);
}

class LoggingCopyBuilder extends CopyBuilder {
  LoggingCopyBuilder() : super();

  @override
  Future build(BuildStep buildStep) async {
    await super.build(buildStep);
    try {
      throw 'SomeError';
    } catch (e, s) {
      buildStep.logger.warning('Warning!', e, s);
      buildStep.logger.severe('Error!', e, s);
    }
  }
}

String _fileExistsError(String builder, List<String> files) {
  return "error: Builder `Instance of '$builder'` declared outputs "
      "`$files` but those files already exist. That build step has been "
      "skipped.";
}
