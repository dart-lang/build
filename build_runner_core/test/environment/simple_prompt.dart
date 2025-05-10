// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/build_runner_core.dart';

void main() async {
  var env = BuildEnvironment(
    await PackageGraph.forThisPackage(),
    assumeTty: true,
  );
  var result = await env.prompt('Select an option!', ['a', 'b', 'c']);
  buildLog.info(result.toString());
}
