// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;

const multiRootScheme = 'org-dartlang-app';
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
final fesWorkerPortPath = p.join('.dart_tool', 'build', 'fes_worker_port');
final packagesFilePath = p.join('.dart_tool', 'package_config.json');
