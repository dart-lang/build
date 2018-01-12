// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';

export 'package:build_runner/src/util/constants.dart';
export 'package:build_test/build_test.dart'
    hide InMemoryAssetReader, InMemoryAssetWriter;

export 'assets.dart';
export 'descriptors.dart';
export 'in_memory_reader.dart';
export 'in_memory_writer.dart';
export 'matchers.dart';
export 'sdk.dart';
export 'test_phases.dart';

Digest computeDigest(String contents) => md5.convert(UTF8.encode(contents));

class ExistsBuilder extends Builder {
  final AssetId idToCheck;
  final Future waitFor;
  final String inputExtension;

  final _hasRanCompleter = new Completer<Null>();
  Future get hasRan => _hasRanCompleter.future;

  ExistsBuilder(this.idToCheck, {this.waitFor, this.inputExtension: ''});

  @override
  Map<String, List<String>> get buildExtensions => {
        inputExtension: ['$inputExtension.exists']
      };

  @override
  Future<Null> build(BuildStep buildStep) async {
    await waitFor; // await works on null too!
    var exists = await buildStep.canRead(idToCheck);
    await buildStep.writeAsString(
        buildStep.inputId.addExtension('.exists'), '$exists');
    _hasRanCompleter.complete(null);
  }
}

class PlaceholderBuilder extends Builder {
  final String inputExtension;
  final Map<String, String> outputExtensionsToContent;

  @override
  Map<String, List<String>> get buildExtensions =>
      {inputExtension: outputExtensionsToContent.keys.toList()};

  PlaceholderBuilder(this.outputExtensionsToContent,
      {this.inputExtension: r'$lib$'});

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
  return new AssetId(inputId.package, newPath);
}
