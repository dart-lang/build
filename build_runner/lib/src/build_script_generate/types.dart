// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';

final packageGraph = new TypeReference((b) => b
  ..symbol = 'PackageGraph'
  ..url = 'package:build_runner/build_runner.dart');

final buildAction = new TypeReference((b) => b
  ..symbol = 'BuildAction'
  ..url = 'package:build_runner/build_runner.dart');

final buildActions = new TypeReference((b) => b
  ..symbol = 'List'
  ..types.add(buildAction));
