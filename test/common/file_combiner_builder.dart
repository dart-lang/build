// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

/// Takes an input file which points at a bunch of other files, and then it
/// writes an `$input.combined` file which concats all the files.
class FileCombinerBuilder implements Builder {
  Future build(BuildStep buildStep) async {
    var lines = buildStep.input.stringContents.split('\n');
    var content = new StringBuffer();
    for (var line in lines) {
      content.write(await buildStep.readAsString(new AssetId.parse(line)));
    }

    var outputId = _combinedAssetId(buildStep.input.id);
    buildStep.writeAsString(new Asset(outputId, content.toString()));
  }

  List<AssetId> declareOutputs(AssetId input) {
    return [_combinedAssetId(input)];
  }
}

AssetId _combinedAssetId(AssetId inputId) =>
    inputId.addExtension('.combined');
