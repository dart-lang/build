// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart'
    show PostProcessBuildStep, PostProcessBuilder;
import 'package:path/path.dart' as p;

import 'web_entrypoint_builder.dart';

class Dart2JsArchiveExtractor implements PostProcessBuilder {
  @override
  final inputExtensions = const [jsEntrypointArchiveExtension];

  @override
  Future<Null> build(PostProcessBuildStep buildStep) async {
    var bytes = await buildStep.readInputAsBytes();
    var archive = new TarDecoder().decodeBytes(bytes);
    for (var file in archive.files) {
      var inputId = buildStep.inputId;
      var id = new AssetId(
          inputId.package, p.url.join(p.url.dirname(inputId.path), file.name));
      await buildStep.writeAsBytes(id, file.content as List<int>);
    }
  }
}
