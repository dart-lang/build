// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

class StubAssetWriter implements AssetWriter {
  @override
  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) =>
      new Future.value(null);
}
