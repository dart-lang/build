// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'web_entrypoint_builder.dart';

class Dart2JsArchiveExtractor implements PostProcessBuilder {
  /// Whether to only output .js files.
  ///
  /// The default in release mode.
  bool filterOutputs;

  Dart2JsArchiveExtractor() : filterOutputs = false;

  Dart2JsArchiveExtractor.fromOptions(BuilderOptions options)
      : filterOutputs = options.config['filter_outputs'] as bool ?? false;

  @override
  final inputExtensions = const [jsEntrypointArchiveExtension];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    var bytes = await buildStep.readInputAsBytes();
    var archive = TarDecoder().decodeBytes(bytes);
    for (var file in archive.files) {
      if (filterOutputs && !file.name.endsWith('.js')) continue;
      var inputId = buildStep.inputId;
      var id = AssetId(
          inputId.package, p.url.join(p.url.dirname(inputId.path), file.name));
      await buildStep.writeAsBytes(id, file.content as List<int>);
    }
    buildStep.deletePrimaryInput();
  }
}
