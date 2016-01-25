// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library build.example.generate;

import 'package:build/build.dart';

import 'copy_builder.dart';

class CopyTransformer extends BuilderTransformer {
  final List<Builder> builders = [new CopyBuilder()];

  CopyTransformer.asPlugin(_);
}
