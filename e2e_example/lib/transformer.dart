// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:build_barback/build_barback.dart';

import 'copy_builder.dart';

/// A pub compatible Transformer built on top of [BuilderTransformer].
class CopyTransformer extends BuilderTransformer {
  CopyTransformer.asPlugin(_) : super(new CopyBuilder());
}
