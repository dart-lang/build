// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/module_cleanup.dart';
import 'package:build_modules/src/module_library_builder.dart';

Builder moduleLibraryBuilder(_) => const ModuleLibraryBuilder();

PostProcessBuilder moduleCleanup(_) => const ModuleCleanup();
