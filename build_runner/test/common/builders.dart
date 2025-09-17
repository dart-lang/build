// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

class CopyingPostProcessBuilder implements PostProcessBuilder {
  final String outputExtension;

  @override
  final inputExtensions = ['.txt'];

  CopyingPostProcessBuilder({this.outputExtension = '.copy'});

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.inputId.addExtension(outputExtension),
      await buildStep.readInputAsString(),
    );
  }
}

class PlaceholderBuilder extends Builder {
  final String inputPlaceholder;
  final BuiltMap<String, String> outputFilenameToContent;

  @override
  Map<String, List<String>> get buildExtensions => {
    // Usually this map is input filename extensions to output filename
    // extensions, for example `.dart` to `.g.dart`.
    //
    // But this builder is about placeholders, which are special keys that
    // are not extensions. So: the key is a placeholder, and the values are
    // full output filenames relative to the placeholder path.
    inputPlaceholder: outputFilenameToContent.keys.toList(),
  };

  PlaceholderBuilder(
    this.outputFilenameToContent, {
    this.inputPlaceholder = r'$lib$',
  });

  @override
  Future build(BuildStep buildStep) async {
    for (final MapEntry(key: outputFilename, value: content)
        in outputFilenameToContent.entries) {
      await buildStep.writeAsString(
        _outputId(buildStep.inputId, inputPlaceholder, outputFilename),
        content,
      );
    }
  }
}

AssetId _outputId(
  AssetId inputId,
  String inputExtension,
  String outputExtension,
) {
  assert(inputId.path.endsWith(inputExtension));
  final newPath =
      inputId.path.substring(0, inputId.path.length - inputExtension.length) +
      outputExtension;
  return AssetId(inputId.package, newPath);
}
