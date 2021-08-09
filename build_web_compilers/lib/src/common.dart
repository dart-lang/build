// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

final defaultAnalysisOptionsId =
    AssetId('build_modules', 'lib/src/analysis_options.default.yaml');

final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));

String defaultAnalysisOptionsArg(ScratchSpace scratchSpace) =>
    '--options=${scratchSpace.fileFor(defaultAnalysisOptionsId).path}';

String sdkDdcKernelPath(bool soundNullSafety) => p.url.join('lib', '_internal',
    soundNullSafety ? 'ddc_outline_sound.dill' : 'ddc_sdk.dill');

String soundnessExt(bool soundNullSafety) =>
    soundNullSafety ? '.sound' : '.unsound';

// TODO: better solution for a .packages file, today we just create a new one
// for every kernel build action.
Future<File> createPackagesFile(Iterable<AssetId> allAssets) async {
  var allPackages = allAssets.map((id) => id.package).toSet();
  var packagesFileDir =
      await Directory.systemTemp.createTemp('kernel_builder_');
  var packagesFile = File(p.join(packagesFileDir.path, '.packages'));
  await packagesFile.create();
  await packagesFile.writeAsString(allPackages
      .map((pkg) => '$pkg:$multiRootScheme:///packages/$pkg')
      .join('\r\n'));
  return packagesFile;
}

/// Validates that [config] only has the top level keys [supportedOptions].
///
/// Throws an [ArgumentError] if not.
void validateOptions(Map<String, dynamic> config, List<String> supportedOptions,
    String builderKey,
    {List<String> deprecatedOptions = const []}) {
  var unsupported = config.keys.where(
      (o) => !supportedOptions.contains(o) && !deprecatedOptions.contains(o));
  if (unsupported.isNotEmpty) {
    throw ArgumentError.value(unsupported.join(', '), builderKey,
        'only $supportedOptions are supported options, but got');
  }
  var deprecated = config.keys.where(deprecatedOptions.contains);
  if (deprecated.isNotEmpty) {
    log.warning('Found deprecated options ${deprecated.join(', ')}. These no '
        'longer have any effect and should be removed.');
  }
}

/// Fixes up the [uris] from a source map so they make sense in a browser
/// context.
///
/// - Strips the scheme from the uri
/// - Strips the top level directory if its not `packages`
///
/// Copied to `web/stack_trace_mapper.dart`, these need to be kept in sync.
List<String> fixSourceMapSources(List<String> uris) {
  return uris.map((source) {
    var uri = Uri.parse(source);
    // We only want to rewrite multi-root scheme uris.
    if (uri.scheme.isEmpty) return source;
    var newSegments = uri.pathSegments.first == 'packages'
        ? uri.pathSegments
        : uri.pathSegments.skip(1);
    return Uri(path: p.url.joinAll(['/', ...newSegments])).toString();
  }).toList();
}
