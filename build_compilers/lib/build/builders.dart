// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_compilers/build_compilers.dart';

Builder moduleBuilder(_) => const ModuleBuilder();
Builder unlinkedSummaryBuilder(_) => const UnlinkedSummaryBuilder();
Builder linkedSummaryBuilder(_) => const LinkedSummaryBuilder();
Builder devCompilerBuilder(_) => const DevCompilerBuilder();
Builder devCompilerBootstrapBuilder(_) => const DevCompilerBootstrapBuilder();
