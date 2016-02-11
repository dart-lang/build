// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:test/test.dart';

import 'package:build/build.dart';

import 'assets.dart';
import 'matchers.dart';

export 'assets.dart';
export 'copy_builder.dart';
export 'file_combiner_builder.dart';
export 'in_memory_reader.dart';
export 'in_memory_writer.dart';
export 'generic_builder_transformer.dart';
export 'matchers.dart';
export 'stub_reader.dart';
export 'stub_writer.dart';

Future wait(int milliseconds) =>
    new Future.delayed(new Duration(milliseconds: milliseconds));

void checkOutputs(Map<String, String> outputs, BuildResult result,
    [Map<AssetId, String> actualAssets]) {
  if (outputs != null) {
    var remainingOutputIds =
        new List.from(result.outputs.map((asset) => asset.id));
    outputs.forEach((serializedId, contents) {
      var asset = makeAsset(serializedId, contents);
      remainingOutputIds.remove(asset.id);

      /// Check that the writer wrote the assets
      if (actualAssets != null) {
        expect(actualAssets, contains(asset.id));
        expect(actualAssets[asset.id], asset.stringContents);
      }

      /// Check that the assets exist in [result.outputs].
      var actual = result.outputs
          .firstWhere((output) => output.id == asset.id, orElse: () => null);
      expect(actual, isNotNull,
          reason: 'Expected to find ${asset.id} in ${result.outputs}.');
      expect(asset, equalsAsset(actual));
    });

    expect(remainingOutputIds, isEmpty,
        reason: 'Unexpected outputs found `$remainingOutputIds`.');
  }
}
