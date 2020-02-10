// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:scratch_space/scratch_space.dart';

final defaultAnalysisOptionsId =
    AssetId('build_modules', 'lib/src/analysis_options.default.yaml');

String defaultAnalysisOptionsArg(ScratchSpace scratchSpace) =>
    '--options=${scratchSpace.fileFor(defaultAnalysisOptionsId).path}';

enum ModuleStrategy { fine, coarse }

ModuleStrategy moduleStrategy(BuilderOptions options) {
  var config = options.config['strategy'] as String ?? 'coarse';
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
void validateOptions(Map<String, dynamic> config, List<String> supportedOptions,
    String builderKey) {
  var unsupportedOptions =
      config.keys.where((o) => !supportedOptions.contains(o));
  if (unsupportedOptions.isNotEmpty) {
    throw ArgumentError.value(unsupportedOptions.join(', '), builderKey,
        'only $supportedOptions are supported options, but got');
  }
}
