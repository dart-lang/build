// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_development_tools/patch_build_dependencies.dart';

void main(List<String> args) {
  if (args.length != 1) {
    print(
      'Usage: dart run tool/bin/patch_build_dependencies.dart <target_dir>',
    );
    exit(1);
  }

  patchBuildDependencies(args.single);
}
