// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:watcher/watcher.dart';

/// A fake [DirectoryWatcher].
///
/// Use the static [FakeWatcher#notifyPath] method to add events.
class FakeWatcher implements DirectoryWatcher {
  String get directory => path;
  final String path;

  FakeWatcher(this.path) {
    watchers.add(this);
  }

  final _eventsController = new StreamController<WatchEvent>();
  Stream<WatchEvent> get events => _eventsController.stream;

  Future get ready => new Future(() {});

  bool get isReady => true;

  /// All watchers.
  static final watchers = <FakeWatcher>[];

  /// Notify all active watchers of [event] if their [FakeWatcher#path] matches.
  /// The path will also be adjusted to remove the path.
  static notifyWatchers(WatchEvent event) {
    for (var watcher in watchers) {
      if (event.path.startsWith(watcher.path)) {
        watcher._eventsController.add(new WatchEvent(event.type, event.path));
      }
    }
  }
}
