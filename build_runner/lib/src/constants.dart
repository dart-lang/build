// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Relative path to the asset graph from the root package dir.
final String assetGraphPath = assetGraphPathFor(_scriptPath);

/// Relative path to the asset graph for a build script at [path]
String assetGraphPathFor(String path) =>
    '$cacheDir/${_scriptHashFor(path)}/asset_graph.json';

final String _scriptPath =
    Platform.script.scheme == 'file'
        ? p.url.joinAll(
          p.split(p.relative(Platform.script.toFilePath(), from: p.current)),
        )
        : Platform.script.path;

/// Directory containing automatically generated build entrypoints.
///
/// Files in this directory must be read to do build script invalidation.
const String entryPointDir = '$cacheDir/entrypoint';

/// The directory to which hidden assets will be written.
String get generatedOutputDirectory => '$cacheDir/generated';

/// Relative path to the cache directory from the root package dir.
const cacheDir = '.dart_tool/build';

/// Returns a hash for a given Dart script path.
///
/// Normalizes between snapshot and Dart source file paths so they give the same
/// hash.
String _scriptHashFor(String path) =>
    md5
        .convert(
          utf8.encode(
            path.endsWith('.snapshot')
                ? path.substring(0, path.length - 9)
                : path,
          ),
        )
        .toString();

/// The dart binary from the current sdk.
final dartBinary = p.join(sdkBin, 'dart');

/// The path to the sdk bin directory on the current platform.
final sdkBin = p.join(sdkPath, 'bin');

/// The path to the sdk on the current platform.
final sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
