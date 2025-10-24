// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// Relative path to the cache directory from the root package dir.
const String cacheDirectoryPath = '.dart_tool/build';

// Entrypoint directory, script, dill and depfile.
const entrypointDirectoryPath = '$cacheDirectoryPath/entrypoint';
const entrypointScriptPath = '$entrypointDirectoryPath/build.dart';

/// Relative path to the asset graph from the root package dir.
final String assetGraphPath = '$cacheDirectoryPath/asset_graph.json';

/// The directory to which hidden assets will be written.
String get generatedOutputDirectory => '$cacheDirectoryPath/generated';

/// The dart binary from the current sdk.
final dartBinary = p.join(sdkBin, 'dart');

/// The path to the sdk bin directory on the current platform.
final sdkBin = p.join(sdkPath, 'bin');

/// The path to the sdk on the current platform.
final sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
