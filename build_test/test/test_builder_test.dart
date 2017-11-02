// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
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
    await testBuilder(new GlobbingBuilder(new Glob('**.txt')), assets,
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
    await testBuilder(new GlobbingBuilder(new Glob('**.txt')), assets,
        rootPackage: 'a', outputs: expectedOutputs);
  });
}
