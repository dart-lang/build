// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

import 'package:e2e_example/copy_builder.dart';
import 'package:e2e_example/packages_dir_builder.dart';

Future main() async {
  // Builds a full package dependency graph for the current package.
  var graph = new PackageGraph.forThisPackage();
  var phases = new PhaseGroup();

  // Give [Builder]s access to a [PackageGraph] so they can choose which
  // packages to run on. This simplifies user code a lot, and helps to mitigate
  // the transitive deps issue.
  CopyBuilder.addPhases(phases, graph);

  // Adds all the phases necessary to copy all files into a fake packages dir!
  PackagesDirBuilder.addPhases(phases, graph);

  watch(phases);
}
