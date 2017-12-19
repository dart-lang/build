// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

class CopyBuilder implements Builder {
  /// If > 1, then multiple copies will be output, using the copy number as an
  /// additional extension.
  final int numCopies;

  /// The file extension to add to files.
  final String extension;

  /// Copies content from this asset into all files, instead of the primary
  /// asset.
  final AssetId copyFromAsset;

  /// Will touch this asset, so that it becomes a dependency.
  final AssetId touchAsset;

  /// No `build` step will complete until this future completes. It may be
  /// re-assigned in between builds.
  Future blockUntil;

  /// The extension of assets this Builder will take as inputs.
  ///
  /// Defaults to the empty string so that all assets are inputs. If any inputs
  /// are passed which do not match the input extension then [build] will throw.
  final String inputExtension;

  /// A stream of all the [BuildStep.inputId]s that are seen.
  ///
  /// Events are added at the top of the [build] method.
  final _buildInputsController = new StreamController<AssetId>.broadcast();
  Stream<AssetId> get buildInputs => _buildInputsController.stream;

  CopyBuilder(
      {this.numCopies: 1,
      this.extension: 'copy',
      this.copyFromAsset,
      this.touchAsset,
      this.inputExtension: '',
      this.blockUntil});

  @override
  Future build(BuildStep buildStep) async {
    // Skip placeholder files from build_runner.
    if (buildStep.inputId.path.endsWith(r'$')) return;

    _buildInputsController.add(buildStep.inputId);
    if (!buildStep.inputId.path.endsWith(inputExtension)) {
      throw new ArgumentError('Only expected inputs with extension '
          '$inputExtension but got ${buildStep.inputId}');
    }
    if (blockUntil != null) await blockUntil;

    var ids = new Iterable<int>.generate(numCopies)
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
    return {inputExtension: outputs};
  }

  AssetId _copiedAssetId(AssetId inputId, int copyNum) => new AssetId(
      inputId.package,
      _replaceSuffix(inputId.path, _copiedAssetExtension(copyNum)));

  String _copiedAssetExtension(int copyNum) =>
      '.$extension${numCopies == 1 ? '' : '.$copyNum'}';

  String _replaceSuffix(String path, String replacement) =>
      path.substring(0, path.length - inputExtension.length) + replacement;
}
