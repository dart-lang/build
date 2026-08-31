// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import 'bootstrap/build_process_state.dart';

/// Relative path to build_runner's hidden directory from the output root.
const String hiddenBuildDirectoryPath = '.dart_tool/build';

// Entrypoint directory, script, dill and depfile.
const entrypointDirectoryPath = '$hiddenBuildDirectoryPath/entrypoint';
const entrypointScriptPath = '$entrypointDirectoryPath/build.dart';

/// Relative path to `asset_graph.json` from the output root.
const assetGraphJsonPath = '$hiddenBuildDirectoryPath/asset_graph.json';

/// Relative path to the artifact tree from the output root.
///
/// The artifact tree is an alternative output location for assets that should
/// not be immediately written to their package paths.
///
/// Outputs still in the artifact tree at the end of the build are "merged" into
/// directories created with `--output` and are served by
/// `dart run build_runner serve`. It's possible to prevent this by using a
/// post process builder to delete specific artifact outputs at the end of the
/// build, making them strictly intermediate artifacts.
const artifactTreePath = '$hiddenBuildDirectoryPath/generated';

/// The dart binary from the current sdk.
String get dartBinary => p.join(sdkBin, 'dart');

/// The path to the sdk bin directory on the current platform.
String get sdkBin => p.join(sdkPath, 'bin');

/// The path to the sdk on the current platform.
String get sdkPath => buildProcessState.dartSdkPath;
