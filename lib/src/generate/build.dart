// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:logging/logging.dart';

import '../asset/cache.dart';
import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../package_graph/package_graph.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'phase.dart';

/// Runs all of the [Phases] in [phaseGroups].
///
/// A [packageGraph] may be supplied, otherwise one will be constructed using
/// [PackageGraph.forThisPackage]. The default functionality assumes you are
/// running in the root directory of a package, with both a `pubspec.yaml` and
/// `.packages` file present.
///
/// A [reader] and [writer] may also be supplied, which can read/write assets
/// to arbitrary locations or file systems. By default they will write directly
/// to the root package directory, and will use the [packageGraph] to know where
/// to read files from.
///
/// Logging may be customized by passing a custom [logLevel] below which logs
/// will be ignored, as well as an [onLog] handler which defaults to [print].
Future<BuildResult> build(List<List<Phase>> phaseGroups,
    {PackageGraph packageGraph,
    AssetReader reader,
    AssetWriter writer,
    Level logLevel: Level.ALL,
    onLog(LogRecord)}) async {
  Logger.root.level = logLevel;
  onLog ??= print;
  var logListener = Logger.root.onRecord.listen(onLog);
  packageGraph ??= new PackageGraph.forThisPackage();
  var cache = new AssetCache();
  reader ??=
      new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
  writer ??=
      new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));

  /// Run the build!
  var result = await new BuildImpl(
          new AssetGraph(), reader, writer, packageGraph, phaseGroups)
      .runBuild();

  await logListener.cancel();

  return result;
}
