// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'id.dart';

abstract class AssetReader {
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8});
}
