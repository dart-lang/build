// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';

// Makes copies of things!
class CopyBuilder extends Builder {
  @override
  Future build(BuildStep buildStep) async {
    var id = buildStep.inputId;
    // ignore: unawaited_futures
    buildStep.writeAsString(_copiedAssetId(id), buildStep.readAsString(id));
  }

  @override
  final buildExtensions = const {
    '': const ['.copy']
  };
}

AssetId _copiedAssetId(AssetId inputId) => inputId.addExtension('.copy');
