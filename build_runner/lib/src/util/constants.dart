// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Relative path to the asset graph from the root package dir.
final String assetGraphPath = '$cacheDir/$scriptHash/asset_graph.json';

/// Directory used for build tooling.
///
/// Reading from this directory may cause non-hermetic builds.
const String toolDir = '.dart_tool';

/// Relative path to the cache directory from the root package dir.
const String cacheDir = '$toolDir/build';

final String scriptHash =
    md5.convert(Platform.script.path.codeUnits).toString();
