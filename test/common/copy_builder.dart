// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

class CopyBuilder implements Builder {
  int numCopies;

  CopyBuilder({this.numCopies: 1});

  Future build(BuildStep buildStep) async {
    var ids = declareOutputs(buildStep.input.id);
    for (var id in ids) {
      buildStep.writeAsString(new Asset(id, buildStep.input.stringContents));
    }
  }

  List<AssetId> declareOutputs(AssetId input) {
    var outputs = [];
    for (int i = 0; i < numCopies; i++) {
      outputs.add(_copiedAssetId(input, numCopies == 1 ? null : i));
    }
    return outputs;
  }
}

AssetId _copiedAssetId(AssetId inputId, int copyNum) =>
    inputId.addExtension('.copy${copyNum == null ? '' : '.$copyNum'}');
