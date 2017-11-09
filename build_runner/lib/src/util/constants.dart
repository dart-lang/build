// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Relative path to the asset graph from the root package dir.
final String assetGraphPath = assetGraphPathFor(Platform.script.path);

/// Relative path to the asset graph for a build script at [path]
String assetGraphPathFor(String path) =>
    '$cacheDir/${scriptHashFor(path)}/asset_graph.json';

/// Directories used for build tooling.
///
/// Reading from these directories may cause non-hermetic builds.
const toolDirs = const [
  '.dart_tool',
  'build',
  'packages',
  '.pub',
  '.git',
  '.idea'
];

/// Directory containing automatically generated build entrypoints.
///
/// Files in this directory must be read to do build script invalidation.
const entryPointDir = '.dart_tool/build/entrypoint';

/// The directory to which assets will be written when `writeToCache` is
/// enabled.
const generatedOutputDirectory = '$cacheDir/generated';

/// Relative path to the cache directory from the root package dir.
const String cacheDir = '.dart_tool/build';

/// Returns a hash for a given path.
String scriptHashFor(String path) => md5.convert(path.codeUnits).toString();
