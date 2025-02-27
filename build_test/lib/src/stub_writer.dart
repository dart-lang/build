// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:build/build.dart';

/// A no-op implementation of [AssetWriter].
class StubAssetWriter implements AssetWriter {
  const StubAssetWriter();

  @override
  Future writeAsBytes(_, _) => Future.value(null);

  @override
  Future writeAsString(_, _, {Encoding encoding = utf8}) => Future.value(null);
}
