// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

class CopyBuilder implements Builder {
  /// If > 0, then multiple copies will be output, using the copy number as an
  /// additional extension.
  final int numCopies;

  /// The file extension to add to files.
  final String extension;

  /// The package in which to output files.
  final String outputPackage;

  /// Copies content from this asset into all files, instead of the primary
  /// asset.
  final AssetId copyFromAsset;

  /// Will touch this asset, so that it becomes a dependency.
  final AssetId touchAsset;

  /// No `build` step will complete until this future completes. It may be
  /// re-assigned in between builds.
  Future blockUntil;

  CopyBuilder(
      {this.numCopies: 1,
      this.extension: 'copy',
      this.outputPackage,
      this.copyFromAsset,
      this.touchAsset,
      this.blockUntil});

  @override
  Future build(BuildStep buildStep) async {
    if (blockUntil != null) await blockUntil;

    var ids = new Iterable.generate(numCopies)
        .map((copy) => _copiedAssetId(buildStep.inputId, copy));
    for (var id in ids) {
      var toCopy = copyFromAsset ?? buildStep.inputId;
      // ignore: unawaited_futures
      buildStep.writeAsString(id, buildStep.readAsString(toCopy));
    }

    if (touchAsset != null) await buildStep.canRead(touchAsset);
  }

  @override
  Map<String, List<String>> get buildExtensions {
    var outputs = <String>[];
    for (int i = 0; i < numCopies; i++) {
      outputs.add(_copiedAssetExtension(i));
    }
    return {'': outputs};
  }

  AssetId _copiedAssetId(AssetId inputId, int copyNum) {
    var withExtension = inputId.addExtension(_copiedAssetExtension(copyNum));
    if (outputPackage == null) {
      return withExtension;
    }
    return new AssetId(outputPackage, withExtension.path);
  }

  String _copiedAssetExtension(int copyNum) =>
      '.$extension${copyNum == null ? '' : '.$copyNum'}';
}
