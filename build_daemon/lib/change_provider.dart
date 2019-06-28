// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:watcher/src/watch_event.dart';

abstract class ChangeProvider {}

/// A provider of changes which are manually collected right before a build.
abstract class ManualChangeProvider implements ChangeProvider {
  Future<List<WatchEvent>> collectChanges();
}

/// A provider of changes which automatically cause builds to occur.
abstract class AutoChangeProvider implements ChangeProvider {
  /// If multiple files change together then they should be sent in the same
  /// event. Otherwise, at least two builds will be triggered.
  Stream<List<WatchEvent>> get changes;
}
