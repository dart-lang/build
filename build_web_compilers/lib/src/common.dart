// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart' show multiRootScheme;
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

final jsModuleErrorsExtension = '.ddc.js.errors';
final jsModuleExtension = '.ddc.js';
final jsSourceMapExtension = '.ddc.js.map';
final metadataExtension = '.ddc.js.metadata';
final symbolsExtension = '.ddc.js.symbols';
final fullKernelExtension = '.ddc.full.dill';

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
  final unsupported = config.keys.where(
    (o) => !supportedOptions.contains(o) && !deprecatedOptions.contains(o),
  );
  if (unsupported.isNotEmpty) {
    throw ArgumentError.value(
      unsupported.join(', '),
      builderKey,
      'only $supportedOptions are supported options, but got',
    );
  }
  final deprecated = config.keys.where(deprecatedOptions.contains);
  if (deprecated.isNotEmpty) {
    log.warning(
      'Found deprecated options ${deprecated.join(', ')}. These no '
      'longer have any effect and should be removed.',
    );
  }
}

/// The url to compile for a source.
///
/// Use the package: path for files under lib and the full absolute path for
/// other files.
String sourceArg(AssetId id) {
  final uri = canonicalUriFor(id);
  return uri.startsWith('package:') ? uri : '$multiRootScheme:///${id.path}';
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
    final uri = Uri.parse(source);
    // We only want to rewrite multi-root scheme uris.
    if (uri.scheme.isEmpty) return source;
    final newSegments =
        uri.pathSegments.first == 'packages'
            ? uri.pathSegments
            : uri.pathSegments.skip(1);
    return Uri(path: p.url.joinAll(['/', ...newSegments])).toString();
  }

  final file = scratchSpace.fileFor(id);
  if (await file.exists()) {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, Object?>;
    final sources = json['sources'] as List<Object?>;
    // Modify `sources` in place for fewer allocations.
    for (var i = 0; i < sources.length; i++) {
      sources[i] = fixMappedSource(sources[i] as String);
    }
    await writer.writeAsString(id, jsonEncode(json));
  }
}

void fixMetadataSources(Map<String, dynamic> json, Uri scratchUri) {
  String updatePath(String path) =>
      Uri.parse(path).path.replaceAll(scratchUri.path, '');

  final sourceMapUri = json['sourceMapUri'] as String?;
  if (sourceMapUri != null) {
    json['sourceMapUri'] = updatePath(sourceMapUri);
  }

  final moduleUri = json['moduleUri'] as String?;
  if (moduleUri != null) {
    json['moduleUri'] = updatePath(moduleUri);
  }

  final fullDillUri = json['fullDillUri'] as String?;
  if (fullDillUri != null) {
    json['fullDillUri'] = updatePath(fullDillUri);
  }

  final libraries = json['libraries'] as List<Object?>?;
  if (libraries != null) {
    for (final lib in libraries) {
      final libraryJson = lib as Map<String, Object?>?;
      if (libraryJson != null) {
        final fileUri = libraryJson['fileUri'] as String?;
        if (fileUri != null) {
          libraryJson['fileUri'] = updatePath(fileUri);
        }
      }
    }
  }
}

/// The module name of [jsId] corresponding to the actual key used by DDC in its
/// boostrapper (which may contain path prefixes).
///
/// Corresponds to the library name for the Library Bundler module system.
String ddcModuleName(AssetId jsId) {
  final jsPath =
      jsId.path.startsWith('lib/')
          ? jsId.path.replaceFirst('lib/', 'packages/${jsId.package}/')
          : jsId.path;
  return jsPath.substring(0, jsPath.length - jsModuleExtension.length);
}

String ddcLibraryId(AssetId jsId) {
  final jsPath =
      jsId.path.startsWith('lib/')
          ? jsId.path.replaceFirst('lib/', 'package:${jsId.package}/')
          : '$multiRootScheme:///${jsId.path}';
  final prefix = jsPath.substring(0, jsPath.length - jsModuleExtension.length);
  return '$prefix.dart';
}

AssetId changeAssetIdExtension(
  AssetId inputId,
  String inputExtension,
  String outputExtension,
) {
  assert(inputId.path.endsWith(inputExtension));
  final newPath =
      inputId.path.substring(0, inputId.path.length - inputExtension.length) +
      outputExtension;
  return AssetId(inputId.package, newPath);
}
