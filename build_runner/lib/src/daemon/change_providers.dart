// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/change_provider.dart';
import 'package:watcher/src/watch_event.dart';

class BuildRunnerAutoChangeProvider implements AutoChangeProvider {
  final Stream<List<WatchEvent>> _changes;

  BuildRunnerAutoChangeProvider(this._changes);

  @override
  Stream<List<WatchEvent>> get changes => _changes;
}

// TODO(grouma) - collect changes through a one time file scan instead of
// buffering changes from a change stream. This will have better performance
// on Windows.
class BuildRunnerManualChangeProvider implements ManualChangeProvider {
  final _changes = <WatchEvent>[];

  BuildRunnerManualChangeProvider(Stream<List<WatchEvent>> changes) {
    changes.listen(_changes.addAll);
  }

  @override
  Future<List<WatchEvent>> collectChanges() async {
    var result = _changes.toList();
    _changes.clear();
    return result;
  }
}
