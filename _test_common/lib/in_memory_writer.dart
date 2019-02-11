// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'package:build_runner_core/build_runner_core.dart';

class InMemoryRunnerAssetWriter extends InMemoryAssetWriter
    implements RunnerAssetWriter {
  void Function(AssetId) onDelete;

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    var type = assets.containsKey(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsBytes(id, bytes);
    FakeWatcher.notifyWatchers(
        WatchEvent(type, p.absolute(id.package, id.path)));
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) async {
    var type = assets.containsKey(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsString(id, contents, encoding: encoding);
    FakeWatcher.notifyWatchers(
        WatchEvent(type, p.absolute(id.package, id.path)));
  }

  @override
  Future delete(AssetId id) async {
    if (onDelete != null) onDelete(id);
    assets.remove(id);
    FakeWatcher.notifyWatchers(
        WatchEvent(ChangeType.REMOVE, p.absolute(id.package, id.path)));
  }
}
