// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/sources.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('Sources', () {
    test('packageFileIds matches only files in the specified package', () {
      final sources = Sources();
      for (final id in [
        // Should match.
        AssetId('a', 'lib/a.dart'),
        AssetId('b', 'lib/a.dart'),
      ]) {
        sources.add(id);
      }
      expect(sources.packageFileIds('a', [AssetId('a', 'lib/a.g.dart')]), [
        AssetId('a', 'lib/a.dart'),
        AssetId('a', 'lib/a.g.dart'),
      ]);
    });

    test('packageFileIds matches paths to glob, sorts results', () {
      final sources = Sources();
      for (final id in [
        AssetId('a', 'lib/aa.dart'),
        AssetId('a', 'lib/ab.dart'),
        AssetId('a', 'lib/aa/a.dart'),
        AssetId('a', 'lib/ba.dart'),
        AssetId('a', 'lib/bb.dart'),
        AssetId('a', 'lib/bb/b.dart'),
      ]) {
        sources.add(id);
      }
      expect(sources.packageFileIds('a', [], glob: Glob('lib/a*.dart')), [
        AssetId('a', 'lib/aa.dart'),
        AssetId('a', 'lib/ab.dart'),
      ]);
      expect(sources.packageFileIds('a', [], glob: Glob('lib/*a.dart')), [
        AssetId('a', 'lib/aa.dart'),
        AssetId('a', 'lib/ba.dart'),
      ]);
      expect(sources.packageFileIds('a', [], glob: Glob('*/aa.dart')), [
        AssetId('a', 'lib/aa.dart'),
      ]);
      expect(sources.packageFileIds('a', [], glob: Glob('*')), isEmpty);

      expect(sources.packageFileIds('a', [], glob: Glob('**')), [
        // Matches are sorted.
        AssetId('a', 'lib/aa.dart'),
        AssetId('a', 'lib/aa/a.dart'),
        AssetId('a', 'lib/ab.dart'),
        AssetId('a', 'lib/ba.dart'),
        AssetId('a', 'lib/bb.dart'),
        AssetId('a', 'lib/bb/b.dart'),
      ]);
      expect(sources.packageFileIds('a', [], glob: Glob('**/a.dart')), [
        AssetId('a', 'lib/aa/a.dart'),
      ]);
    });

    test('findFirstWithPrefix finds first with prefix in large list', () {
      final list = <AssetId>[
        AssetId('a', 'a'),
        AssetId('a', 'ab'),
        AssetId('a', 'c'),
        AssetId('a', 'd'),
      ];
      expect(list.findFirstWithPrefix('a'), 0);
      expect(list.findFirstWithPrefix('b'), -1);
      expect(list.findFirstWithPrefix('c'), 2);
      expect(list.findFirstWithPrefix('d'), 3);
      expect(list.findFirstWithPrefix('e'), -1);
    });

    test('findFirstWithPrefix finds first with prefix in large list', () {
      final list = <AssetId>[
        for (var i = 0; i != 1000; ++i)
          AssetId('a', '${i.toString().padLeft(4, '0')}andsomeothertext'),
      ];
      for (var i = 0; i != 1000; ++i) {
        expect(list.findFirstWithPrefix(i.toString().padLeft(4, '0')), i);
      }
    });

    test('filterToPrefix filters to prefix', () {
      final list = <AssetId>[
        AssetId('a', 'aa'),
        AssetId('a', 'ab'),
        AssetId('a', 'bb'),
        AssetId('a', 'bc'),
        AssetId('a', 'de'),
      ];
      expect(list.filterToPrefix('a'), [
        AssetId('a', 'aa'),
        AssetId('a', 'ab'),
      ]);
      expect(list.filterToPrefix('aa'), [AssetId('a', 'aa')]);
      expect(list.filterToPrefix('aaa'), isEmpty);
      expect(list.filterToPrefix('aab'), isEmpty);
      expect(list.filterToPrefix('b'), [
        AssetId('a', 'bb'),
        AssetId('a', 'bc'),
      ]);
      expect(list.filterToPrefix('d'), [AssetId('a', 'de')]);
      expect(list.filterToPrefix('de'), [AssetId('a', 'de')]);
      expect(list.filterToPrefix('e'), isEmpty);
    });
  });

  test('simpleGlobPrefix', () {
    expect(simpleGlobPrefix(Glob('*def')), '');
    expect(simpleGlobPrefix(Glob('abc*def')), 'abc');
    expect(simpleGlobPrefix(Glob('abc?def')), 'abc');
    expect(simpleGlobPrefix(Glob('abc{def,ghi}')), 'abc');
    expect(simpleGlobPrefix(Glob('abc[def]')), 'abc');
    expect(simpleGlobPrefix(Glob(r'abc\def')), 'abc');
    expect(simpleGlobPrefix(Glob(r'abcdef*')), 'abcdef');
  });
}
