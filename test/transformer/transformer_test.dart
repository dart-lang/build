// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:test/test.dart';
import 'package:transformer_test/utils.dart';

import '../common/common.dart';

main() {
  var singleCopyTransformer =
      new GenericBuilderTransformer([new CopyBuilder()]);
  var multiCopyTransformer =
      new GenericBuilderTransformer([new CopyBuilder(numCopies: 2)]);
  var singleAndMultiCopyTransformer = new GenericBuilderTransformer(
      [new CopyBuilder(), new CopyBuilder(numCopies: 2)]);

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
      new GenericBuilderTransformer([new CopyBuilder(), new CopyBuilder()])
    ],
  ], {
    'a|web/a.txt': 'hello',
  }, {}, [
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

  testPhases('cant overwrite files', [
    [singleCopyTransformer]
  ], {
    'a|web/a.txt': 'hello',
    'a|web/a.txt.copy': 'hello',
  }, {}, [
    _fileExistsError("CopyBuilder", ["a|web/a.txt.copy"]),
  ]);

  // TODO(jakemac): Skipped because we can't detect this situation today.
  // Instead you get a barback error, see
  // https://github.com/dart-lang/transformer_test/issues/2
  //
  // testPhases('builders in the same phase can\'t output the same file', [
  //   [singleCopyTransformer, new GenericBuilderTransformer([new CopyBuilder()])]
  // ], {
  //   'a|web/a.txt': 'hello',
  // }, {
  //   'a|web/a.txt.copy': 'hello',
  // }, [
  //   _fileExistsError("CopyBuilder", ["a|web/a.txt.copy"]),
  // ]);

  testPhases('builders in separate phases can\'t output the same file', [
    [singleCopyTransformer],
    [singleCopyTransformer],
  ], {
    'a|web/a.txt': 'hello',
  }, {
    'a|web/a.txt.copy': 'hello',
  }, [
    _fileExistsError("CopyBuilder", ["a|web/a.txt.copy"]),
  ]);
}

String _fileExistsError(String builder, List<String> files) {
  return "error: Builder `Instance of '$builder'` declared outputs "
      "`$files` but those files already exist. That build step has been "
      "skipped.";
}
