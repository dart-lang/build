// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:watcher/watcher.dart';

typedef DirectoryWatcher DirectoryWatcherFactory(String path);

DirectoryWatcher defaultDirectoryWatcherFactory(String path) =>
    // TODO: Use `DirectoryWatcher` on windows. See the following issues:
    // - https://github.com/dart-lang/build/issues/1031
    // - https://github.com/dart-lang/watcher/issues/52
    Platform.isWindows
        ? new PollingDirectoryWatcher(path)
        : new DirectoryWatcher(path);
