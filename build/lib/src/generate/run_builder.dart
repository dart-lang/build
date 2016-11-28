// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/asset.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/builder.dart';
import '../builder/build_step.dart';

/// Run [builder] on each asset in [inputs].
///
///
/// If [rootPackage] is not provided all [inputs] must be for the same
/// package, and outputs are only allowed in this package. Builds for all
/// inputs are run asynchronously and ordering is not guaranteed.
Future<Null> runBuilder(Builder builder, Iterable<AssetId> inputs,
    AssetReader reader, AssetWriter writer, Resolvers resolvers,
    {Logger logger, String rootPackage}) async {
  logger ??= new Logger('runBuilder');
  rootPackage ??= new Set.from(inputs.map((input) => input.package)).single;
  //TODO(nbosch) check overlapping outputs?
  Future<Null> buildForInput(AssetId input) async {
    var inputAsset = new Asset(input, await reader.readAsString(input));
    var expectedOutputs = builder.declareOutputs(input);
    var buildStep = new ManagedBuildStep(
        inputAsset, expectedOutputs, reader, writer, rootPackage, resolvers,
        logger: logger);
    await builder.build(buildStep);
    await buildStep.complete();
  }

  await Future.wait(inputs.map(buildForInput));
}
