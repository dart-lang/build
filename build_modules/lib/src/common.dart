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
    new AssetId('build_modules', 'lib/src/analysis_options.default.yaml');

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

enum ModuleStrategy { fine, coarse }

ModuleStrategy moduleStrategy(BuilderOptions options) {
  if (options.isRoot) {
    var config = options.config['strategy'] as String ?? 'fine';
    switch (config) {
      case 'coarse':
        return ModuleStrategy.coarse;
      case 'fine':
        return ModuleStrategy.fine;
      default:
        throw 'Unexpected ModuleBuilder strategy: $config';
    }
  } else {
    return ModuleStrategy.coarse;
  }
}

/// Validates that [config] only has the top level keys [supportedOptions].
///
/// Throws an [ArgumentError] if not.
void validateOptions(Map<String, dynamic> config, List<String> supportedOptions,
    String builderKey) {
  var unsupportedOptions =
      config.keys.where((o) => !supportedOptions.contains(o));
  if (unsupportedOptions.isNotEmpty) {
    throw new ArgumentError.value(unsupportedOptions.join(', '), builderKey,
        'only $supportedOptions are supported options, but got');
  }
}
