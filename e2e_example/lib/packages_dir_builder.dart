// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:path/path.dart' as p;

import 'package:build/build.dart';

// Makes copies of things!
class PackagesDirBuilder extends Builder {
  final String outputDir;
  final String outputPackage;

  PackagesDirBuilder(this.outputPackage, this.outputDir);

  @override
  Future build(BuildStep buildStep) async {
    var id = buildStep.inputId;
    buildStep.writeAsString(
        _copiedAssetId(id), await buildStep.readAsString(id));
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) => [_copiedAssetId(inputId)];

  AssetId _copiedAssetId(AssetId inputId) => new AssetId(
      outputPackage,
      // Creating a folder actually called `packages` breaks things.
      p.join(outputDir, '_packages', inputId.package,
          inputId.path.replaceFirst('lib/', '')));
}
