// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

const multiRootScheme = 'org-dartlang-app';
const webHotReloadOption = 'web-hot-reload';
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
final packagesFilePath = p.join('.dart_tool', 'package_config.json');

final defaultAnalysisOptionsId = AssetId(
  'build_modules',
  'lib/src/analysis_options.default.yaml',
);

String defaultAnalysisOptionsArg(ScratchSpace scratchSpace) =>
    '--options=${scratchSpace.fileFor(defaultAnalysisOptionsId).path}';

enum ModuleStrategy { fine, coarse }

ModuleStrategy moduleStrategy(BuilderOptions options) {
  // DDC's Library Bundle module system only supports fine modules since it must
  // align with the Frontend Server's library management scheme.
  final usesWebHotReload = options.config[webHotReloadOption] as bool? ?? false;
  if (usesWebHotReload) {
    return ModuleStrategy.fine;
  }
  final config = options.config['strategy'] as String? ?? 'coarse';
  switch (config) {
    case 'coarse':
      return ModuleStrategy.coarse;
    case 'fine':
      return ModuleStrategy.fine;
    default:
      throw ArgumentError('Unexpected ModuleBuilder strategy: $config');
  }
}

/// Validates that [config] only has the top level keys [supportedOptions].
///
/// Throws an [ArgumentError] if not.
void validateOptions(
  Map<String, dynamic> config,
  List<String> supportedOptions,
  String builderKey,
) {
  final unsupportedOptions = config.keys.where(
    (o) => !supportedOptions.contains(o),
  );
  if (unsupportedOptions.isNotEmpty) {
    throw ArgumentError.value(
      unsupportedOptions.join(', '),
      builderKey,
      'only $supportedOptions are supported options, but got',
    );
  }
}
