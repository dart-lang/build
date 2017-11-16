// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';

import 'node.dart';

class DuplicateAssetNodeException implements Exception {
  final AssetNode assetNode;

  DuplicateAssetNodeException(this.assetNode);

  @override
  String toString() => 'DuplicateAssetNodeError: $assetNode\n'
      'This probably means you have multiple actions that are trying to output '
      'the same file.';
}

class AssetGraphVersionException implements Exception {
  final int versionSeen;
  final int currentVersion;

  AssetGraphVersionException(this.versionSeen, this.currentVersion);

  @override
  String toString() => 'AssetGraphVersionException: saw version $versionSeen '
      'but the current version is $currentVersion.';
}

class InvalidPackageBuilderOutputsException implements Exception {
  final PackageBuildAction action;
  final Iterable<AssetId> invalidOutputs;
  final String rootPackage;

  InvalidPackageBuilderOutputsException(
      this.action, this.invalidOutputs, this.rootPackage);

  @override
  String toString() =>
      'The root package is $rootPackage but the PackageBuilder '
      '${action.builder} declared ${invalidOutputs.length} outputs '
      'outside the `lib` directory of the `${action.package}` package.\n'
      'Those declared outputs were:\n\n${invalidOutputs.join('\n')}';
}
