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
      'a|lib/a.placeholder': '',
      'a|lib/a.txt': '',
      'a|lib/b.txt': '',
      'a|lib/c.txt': '',
      'a|lib/d.txt': '',
    };
    var expectedOutputs = {
      'a|lib/a.allTxtFiles': allOf(
          contains('a|lib/a.txt'),
          contains('a|lib/b.txt'),
          contains('a|lib/c.txt'),
          contains('a|lib/d.txt')),
    };
    await testBuilder(new GlobbingBuilder(), assets,
        rootPackage: 'a', outputs: expectedOutputs);
  });

  test('can glob files in non-root and root packages', () async {
    var assets = {
      'a|lib/a.placeholder': '',
      'a|lib/a.txt': '',
      'a|lib/b.txt': '',
      'b|lib/b.placeholder': '',
      'b|lib/a.txt': '',
      'b|lib/b.txt': '',
      'b|lib/c.txt': '',
      'b|lib/d.txt': '',
    };
    var expectedOutputs = {
      'a|lib/a.allTxtFiles':
          allOf(contains('a|lib/a.txt'), contains('a|lib/b.txt')),
      'b|lib/b.allTxtFiles': allOf(
          contains('b|lib/a.txt'),
          contains('b|lib/b.txt'),
          contains('b|lib/c.txt'),
          contains('b|lib/d.txt')),
    };
    await testBuilder(new GlobbingBuilder(), assets,
        rootPackage: 'a', outputs: expectedOutputs);
  });
}

class GlobbingBuilder extends Builder {
  @override
  final buildExtensions = {
    '.placeholder': ['.allTxtFiles']
  };

  @override
  Future build(BuildStep buildStep) async {
    var allTxtAssets = buildStep.findAssets(new Glob('**.txt'));
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.allTxtFiles'),
        allTxtAssets.map((id) => id.toString()).join('\n'));
  }
}
