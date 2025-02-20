// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

final defaultAnalysisOptionsId = AssetId(
  'build_modules',
  'lib/src/analysis_options.default.yaml',
);

final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));

String defaultAnalysisOptionsArg(ScratchSpace scratchSpace) =>
    '--options=${scratchSpace.fileFor(defaultAnalysisOptionsId).path}';

String get sdkDdcKernelPath =>
    p.url.join('lib', '_internal', 'ddc_outline.dill');

/// Validates that [config] only has the top level keys [supportedOptions].
///
/// Throws an [ArgumentError] if not.
void validateOptions(
  Map<String, dynamic> config,
  List<String> supportedOptions,
  String builderKey, {
  List<String> deprecatedOptions = const [],
}) {
  var unsupported = config.keys.where(
    (o) => !supportedOptions.contains(o) && !deprecatedOptions.contains(o),
  );
  if (unsupported.isNotEmpty) {
    throw ArgumentError.value(
      unsupported.join(', '),
      builderKey,
      'only $supportedOptions are supported options, but got',
    );
  }
  var deprecated = config.keys.where(deprecatedOptions.contains);
  if (deprecated.isNotEmpty) {
    log.warning(
      'Found deprecated options ${deprecated.join(', ')}. These no '
      'longer have any effect and should be removed.',
    );
  }
}

/// If [id] exists, assume it is a source map and fix up the source uris from
/// it so they make sense in a browser context, then write the modified version
/// using [writer].
///
/// - Strips the scheme from the uri
/// - Strips the top level directory if its not `packages`
Future<void> fixAndCopySourceMap(
  AssetId id,
  ScratchSpace scratchSpace,
  AssetWriter writer,
) async {
  // Copied to `web/stack_trace_mapper.dart`, these need to be kept in sync.
  String fixMappedSource(String source) {
    var uri = Uri.parse(source);
    // We only want to rewrite multi-root scheme uris.
    if (uri.scheme.isEmpty) return source;
    var newSegments =
        uri.pathSegments.first == 'packages'
            ? uri.pathSegments
            : uri.pathSegments.skip(1);
    return Uri(path: p.url.joinAll(['/', ...newSegments])).toString();
  }

  var file = scratchSpace.fileFor(id);
  if (await file.exists()) {
    var content = await file.readAsString();
    var json = jsonDecode(content) as Map<String, Object?>;
    var sources = json['sources'] as List<Object?>;
    // Modify `sources` in place for fewer allocations.
    for (var i = 0; i < sources.length; i++) {
      sources[i] = fixMappedSource(sources[i] as String);
    }
    await writer.writeAsString(id, jsonEncode(json));
  }
}
