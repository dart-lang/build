// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Relative path to the asset graph from the root package dir.
final String assetGraphPath = assetGraphPathFor(_scriptPath);

/// Relative path to the asset graph for a build script at [path]
String assetGraphPathFor(String path) =>
    '$cacheDir/${_scriptHashFor(path)}/asset_graph.json';

/// Relative path to the directory which holds serialized versions of errors
/// reported during previous builds.
final errorCachePath =
    p.url.join(cacheDir, _scriptHashFor(_scriptPath), 'error_cache');

final String _scriptPath = Platform.script.scheme == 'file'
    ? p.url.joinAll(
        p.split(p.relative(Platform.script.toFilePath(), from: p.current)))
    : Platform.script.path;

/// Directory containing automatically generated build entrypoints.
///
/// Files in this directory must be read to do build script invalidation.
const entryPointDir = '.dart_tool/build/entrypoint';

/// The directory to which hidden assets will be written.
const generatedOutputDirectory = '$cacheDir/generated';

/// Relative path to the cache directory from the root package dir.
const String cacheDir = '.dart_tool/build';

/// Returns a hash for a given path.
String _scriptHashFor(String path) => md5.convert(path.codeUnits).toString();

/// The name of the pub binary on the current platform.
final pubBinary = p.join(sdkBin, Platform.isWindows ? 'pub.bat' : 'pub');

/// The path to the sdk bin directory on the current platform.
final sdkBin = p.join(sdkPath, 'bin');

/// The path to the sdk on the current platform.
final sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));

/// The maximum number of concurrent actions to run per build phase.
const buildPhasePoolSize = 16;
