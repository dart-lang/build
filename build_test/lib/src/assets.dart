// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build_runner/src/build_file.dart';
// ignore: implementation_imports
import 'package:build_runner/src/constants.dart';
import 'package:path/path.dart' as p;

import 'test_reader_writer.dart';

int _nextId = 0;
AssetId makeAssetId([String? assetIdString]) {
  if (assetIdString == null) {
    assetIdString = 'a|web/asset_$_nextId.txt';
    _nextId++;
  }
  return AssetId.parse(assetIdString);
}

/// Converts a serialized test fixture descriptor to a [BuildFile].
///
/// Supports serialized IDs of the form `package|path`, or paths like
/// `.dart_tool/...` or `.dart_tool/build/generated/...`.
BuildFile makeBuildFile(String descriptor, {required String defaultPackage}) {
  final pipeIndex = descriptor.indexOf('|');
  final package = pipeIndex == -1
      ? defaultPackage
      : descriptor.substring(0, pipeIndex);
  final path = pipeIndex == -1
      ? descriptor
      : descriptor.substring(pipeIndex + 1);

  final posixPath = p.posix.normalize(path.replaceAll(r'\', '/'));
  final lowerPosixPath = posixPath.toLowerCase();
  if (lowerPosixPath.startsWith('${generatedOutputDirectory.toLowerCase()}/')) {
    final packagePath = posixPath.substring(
      generatedOutputDirectory.length + 1,
    );
    final firstSlash = packagePath.indexOf('/');
    if (firstSlash != -1) {
      final targetPackage = packagePath.substring(0, firstSlash);
      final targetPath = packagePath.substring(firstSlash + 1);
      return AssetFile.cache(AssetId(targetPackage, targetPath));
    }
  }
  if (lowerPosixPath == '.dart_tool' ||
      lowerPosixPath.startsWith('.dart_tool/')) {
    return InternalFile(package, posixPath);
  }
  return AssetFile.source(AssetId(package, posixPath));
}

void addAssets(Map<AssetId, dynamic> assets, TestReaderWriter writer) {
  assets.forEach((id, value) {
    if (value is String) {
      writer.testing.writeString(id, value);
    } else if (value is List<int>) {
      writer.testing.writeBytes(id, value);
    } else {
      throw ArgumentError(
        '`assets` values must be of type `String` or `List<int>`, got '
        '${value.runtimeType}.',
      );
    }
  });
}
