// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';

export 'package:build_test/build_test.dart';
export 'package:build_test/src/internal_test_reader_writer.dart';

export 'builders.dart';
export 'descriptors.dart';
export 'matchers.dart';
export 'package_graphs.dart';
export 'sdk.dart';
export 'test_phases.dart';

Digest computeDigest(AssetId id, String contents) {
  // Tests use `$$` at the start of an ID to signal "generated", remove it.
  var idString = id.toString();
  if (idString.startsWith(r'$$')) idString = idString.substring(2);

  return md5.convert([...utf8.encode(contents), ...idString.codeUnits]);
}
