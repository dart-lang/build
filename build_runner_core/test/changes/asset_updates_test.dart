// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner_core/src/changes/asset_updates.dart';
import 'package:build_runner_core/src/logging/log_renderer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  final renderer = LogRenderer(rootPackageName: 'foo');
  group('AssetUpdates', () {
    test('explains no updates', () {
      expect(
        AssetUpdates(
          added: BuiltSet(),
          modified: BuiltSet(),
          removed: BuiltSet(),
        ).render(renderer),
        'Updates: none.',
      );
    });

    test('explains updates', () {
      expect(
        AssetUpdates(
          added: {AssetId('foo', 'lib1.dart')}.build(),
          modified:
              {
                AssetId('foo', 'lib2.dart'),
                AssetId('foo', 'lib3.dart'),
                AssetId('foo', 'lib4.dart'),
              }.build(),
          removed:
              {
                AssetId('foo', 'lib5.dart'),
                AssetId('foo', 'lib6.dart'),
                AssetId('foo', 'lib7.dart'),
                AssetId('foo', 'lib8.dart'),
                AssetId('foo', 'lib9.dart'),
              }.build(),
        ).render(renderer),
        'Updates: added lib1.dart; '
        'modified lib2.dart, lib3.dart, lib4.dart; '
        'removed lib5.dart, lib6.dart, lib7.dart, (2 more).',
      );
    });

    test('from Map', () {
      expect(
        AssetUpdates.from({
          // `from` sorts by `AssetId`.
          AssetId('foo', 'lib1.dart'): ChangeType.ADD,
          AssetId('foo', 'lib4.dart'): ChangeType.MODIFY,
          AssetId('foo', 'lib3.dart'): ChangeType.MODIFY,
          AssetId('foo', 'lib2.dart'): ChangeType.MODIFY,
          AssetId('foo', 'lib9.dart'): ChangeType.REMOVE,
          AssetId('foo', 'lib8.dart'): ChangeType.REMOVE,
          AssetId('foo', 'lib7.dart'): ChangeType.REMOVE,
          AssetId('foo', 'lib6.dart'): ChangeType.REMOVE,
          AssetId('foo', 'lib5.dart'): ChangeType.REMOVE,
        }).render(renderer),
        'Updates: added lib1.dart; '
        'modified lib2.dart, lib3.dart, lib4.dart; '
        'removed lib5.dart, lib6.dart, lib7.dart, (2 more).',
      );
    });
  });
}
