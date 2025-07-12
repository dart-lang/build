// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

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

/// A [Builder] which behaves exactly like it's [delegate] but has a different
/// runtime type.
class DelegatingBuilder implements Builder {
  final Builder delegate;

  DelegatingBuilder(this.delegate);

  @override
  Map<String, List<String>> get buildExtensions => delegate.buildExtensions;

  @override
  Future build(BuildStep buildStep) async => delegate.build(buildStep);
}

class PlaceholderBuilder extends Builder {
  final String inputExtension;
  final Map<String, String> outputExtensionsToContent;

  @override
  Map<String, List<String>> get buildExtensions => {
    inputExtension: outputExtensionsToContent.keys.toList(),
  };

  PlaceholderBuilder(
    this.outputExtensionsToContent, {
    this.inputExtension = r'$lib$',
  });

  @override
  Future build(BuildStep buildStep) async {
    outputExtensionsToContent.forEach((extension, content) {
      buildStep.writeAsString(
        _outputId(buildStep.inputId, inputExtension, extension),
        content,
      );
    });
  }
}

AssetId _outputId(
  AssetId inputId,
  String inputExtension,
  String outputExtension,
) {
  assert(inputId.path.endsWith(inputExtension));
  var newPath =
      inputId.path.substring(0, inputId.path.length - inputExtension.length) +
      outputExtension;
  return AssetId(inputId.package, newPath);
}
