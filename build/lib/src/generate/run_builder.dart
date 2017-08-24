// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/id.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/build_step_impl.dart';
import '../builder/builder.dart';
import '../builder/logging.dart';
import 'expected_outputs.dart';

/// Run [builder] with each asset in [inputs] as the primary input.
///
/// Builds for all inputs are run asynchronously and ordering is not guaranteed.
/// The [log] instance inside the builds will be scoped to [logger] which is
/// defaulted to a [Logger] name 'runBuilder'.
Future<Null> runBuilder(Builder builder, Iterable<AssetId> inputs,
    AssetReader reader, AssetWriter writer, Resolvers resolvers,
    {Logger logger, @deprecated String rootPackage}) async {
  logger ??= new Logger('runBuilder');
  //TODO(nbosch) check overlapping outputs?
  Future<Null> buildForInput(AssetId input) async {
    var outputs = expectedOutputs(builder, input);
    if (outputs.isEmpty) return;
    var buildStep = new BuildStepImpl(input, outputs, reader, writer,
        rootPackage ?? input.package, resolvers);
    try {
      await builder.build(buildStep);
    } finally {
      await buildStep.complete();
    }
  }

  await scopeLog(() => Future.wait(inputs.map(buildForInput)), logger);
}
