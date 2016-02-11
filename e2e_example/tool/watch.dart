// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:build/build.dart';

import 'package:e2e_example/copy_builder.dart';

main() async {
  /// Builds a full package dependency graph for the current package.
  var graph = new PackageGraph.forThisPackage();

  /// Give [Builder]s access to a [PackageGraph] so they can choose which
  /// packages to run on. This simplifies user code a lot, and helps to mitigate
  /// the transitive deps issue.
  var phases = CopyBuilder.buildPhases(graph);

  await for (var result in watch([phases])) {
    print(result);
  }
}
