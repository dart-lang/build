// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build_runner/build_runner.dart';

import 'package:e2e_example/copy_builder.dart';
import 'package:e2e_example/packages_dir_builder.dart';

Future main() async {
  // Builds a full package dependency graph for the current package.
  var graph = new PackageGraph.forThisPackage();
  var phases = new PhaseGroup()
    ..newPhase().addAction(
        new CopyBuilder(), new InputSet(graph.root.name, ['**/*.txt']));

  var packagesDirBuilder = new PackagesDirBuilder(graph.root.name, 'web');
  var phase = phases.newPhase();
  for (var package in graph.allPackages.values) {
    phase.addAction(packagesDirBuilder, new InputSet(package.name, ['lib/**']));
  }

  watch(phases);
}
