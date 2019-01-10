// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';

export 'package:build_runner_core/src/util/constants.dart';
export 'package:build_test/build_test.dart'
    hide InMemoryAssetReader, InMemoryAssetWriter;

export 'assets.dart';
export 'builders.dart';
export 'descriptors.dart';
export 'in_memory_reader.dart';
export 'in_memory_writer.dart';
export 'matchers.dart';
export 'package_graphs.dart';
export 'sdk.dart';
export 'test_phases.dart';

Digest computeDigest(AssetId id, String contents) {
  // Special handling for `$$` assets, these are generated under the .dart_tool
  // dir and unfortunately that leaks into the digest computations.
  if (id.package.startsWith(r'$$')) {
    var package = id.package.substring(2);
    id = AssetId(package, '.dart_tool/build/generated/$package/${id.path}');
  }
  return md5.convert(
      utf8.encode(contents).followedBy(id.toString().codeUnits).toList());
}

class PlaceholderBuilder extends Builder {
  final String inputExtension;
  final Map<String, String> outputExtensionsToContent;

  @override
  Map<String, List<String>> get buildExtensions =>
      {inputExtension: outputExtensionsToContent.keys.toList()};

  PlaceholderBuilder(this.outputExtensionsToContent,
      {this.inputExtension = r'$lib$'});

  @override
  Future build(BuildStep buildStep) async {
    outputExtensionsToContent.forEach((extension, content) {
      buildStep.writeAsString(
          _outputId(buildStep.inputId, inputExtension, extension), content);
    });
  }
}

AssetId _outputId(
    AssetId inputId, String inputExtension, String outputExtension) {
  assert(inputId.path.endsWith(inputExtension));
  var newPath =
      inputId.path.substring(0, inputId.path.length - inputExtension.length) +
          outputExtension;
  return AssetId(inputId.package, newPath);
}
