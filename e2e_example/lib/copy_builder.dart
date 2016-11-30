// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

// Makes copies of things!
class CopyBuilder extends Builder {
  @override
  Future build(BuildStep buildStep) async {
    var input = buildStep.input;
    var copy = new Asset(_copiedAssetId(input.id), input.stringContents);
    buildStep.writeAsString(copy);
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) => [_copiedAssetId(inputId)];
}

AssetId _copiedAssetId(AssetId inputId) => inputId.addExtension('.copy');
