// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'kernel_builder.dart';

final defaultAnalysisOptionsId =
    new AssetId('build_web_compilers', 'lib/src/analysis_options.default.yaml');

String defaultAnalysisOptionsArg(ScratchSpace scratchSpace) =>
    '--options=${scratchSpace.fileFor(defaultAnalysisOptionsId).path}';

// TODO: better solution for a .packages file, today we just create a new one
// for every kernel build action.
Future<File> createPackagesFile(
    Iterable<AssetId> allAssets, ScratchSpace scratchSpace) async {
  var allPackages = allAssets.map((id) => id.package).toSet();
  var packagesFileDir =
      await Directory.systemTemp.createTemp('kernel_builder_');
  var packagesFile = new File(p.join(packagesFileDir.path, '.packages'));
  await packagesFile.create();
  await packagesFile.writeAsString(allPackages
      .map((pkg) => '$pkg:$multiRootScheme:///packages/$pkg')
      .join('\r\n'));
  return packagesFile;
}
