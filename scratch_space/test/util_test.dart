// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:scratch_space/src/util.dart';

void main() {
  group('topLevelDir', () {
    test('returns the top level dir in a path', () {
      expect(topLevelDir('foo/bar/baz.dart'), 'foo');
      expect(topLevelDir('foo/../bar/baz.dart'), 'bar');
      expect(topLevelDir('./foo/baz.dart'), 'foo');
    });

    test('throws for invalid paths', () {
      expect(() => topLevelDir('../bar.dart'), throwsArgumentError,
          reason: 'Paths reaching outside the root dir should throw.');
      expect(() => topLevelDir('foo/../../bar.dart'), throwsArgumentError,
          reason: 'Paths reaching outside the root dir should throw.');
    });

    test('allows without a top level directory', () {
      expect(topLevelDir('foo.dart'), null);
    });
  });
}
