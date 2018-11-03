// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:build_test/build_test.dart';

void main() {
  test('can glob files in the root package', () async {
    var assets = {
      'a|lib/a.globPlaceholder': '',
      'a|lib/a.txt': '',
      'a|lib/b.txt': '',
      'a|lib/c.txt': '',
      'a|lib/d.txt': '',
    };
    var expectedOutputs = {
      'a|lib/a.matchingFiles':
          'a|lib/a.txt\na|lib/b.txt\na|lib/c.txt\na|lib/d.txt',
    };
    await testBuilder(GlobbingBuilder(Glob('**.txt')), assets,
        rootPackage: 'a', outputs: expectedOutputs);
  });

  test('can glob files in non-root and root packages', () async {
    var assets = {
      'a|lib/a.globPlaceholder': '',
      'a|lib/a.txt': '',
      'a|lib/b.txt': '',
      'b|lib/b.globPlaceholder': '',
      'b|lib/a.txt': '',
      'b|lib/b.txt': '',
      'b|lib/c.txt': '',
      'b|lib/d.txt': '',
    };
    var expectedOutputs = {
      'a|lib/a.matchingFiles': decodedMatches(
          allOf(contains('a|lib/a.txt'), contains('a|lib/b.txt'))),
      'b|lib/b.matchingFiles': decodedMatches('b|lib/a.txt\n'
          'b|lib/b.txt\n'
          'b|lib/c.txt\n'
          'b|lib/d.txt'),
    };
    await testBuilder(GlobbingBuilder(Glob('**.txt')), assets,
        rootPackage: 'a', outputs: expectedOutputs);
  });

  group('can output special placeholder outpout files', () {
    const placeholders = ['lib', 'web', 'test'];

    for (var dir in placeholders) {
      test('using the special "$dir" sset', () async {
        var assets = {
          'a|data/1.txt': '1',
          'a|data/2.txt': '2',
          'a|data/3.txt': '3',
        };

        var outputs = {
          'a|$dir/concat.txt': '1\n2\n3\n',
        };

        await testBuilder(
          _ConcatBuilder(dir),
          assets,
          rootPackage: 'a',
          outputs: outputs,
        );
      });
    }
  });
}

/// Concatenates the contents of multiple text files into a single output.
class _ConcatBuilder implements Builder {
  final String _input;

  _ConcatBuilder(this._input) {
    buildExtensions = {
      '\$$_input\$': ['concat.txt'],
    };
  }

  @override
  Future<Null> build(BuildStep buildStep) async {
    final results = StringBuffer();
    await for (final asset in buildStep.findAssets(Glob('data/*.txt'))) {
      results.writeln(await buildStep.readAsString(asset));
    }
    final output = AssetId(buildStep.inputId.package, '$_input/concat.txt');
    await buildStep.writeAsString(output, results.toString());
  }

  @override
  Map<String, List<String>> buildExtensions;
}
