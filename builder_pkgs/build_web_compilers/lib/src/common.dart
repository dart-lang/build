// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

const multiRootScheme = 'org-dartlang-app';
const testScratchSpacePathPrefix = 'test_scratch_space/';
final fesManagerConfigPath = p.join(
  '.dart_tool',
  'build',
  'fes_manager_config',
);
final packagesFilePath = p.join('.dart_tool', 'package_config.json');
const webHotReloadOption = 'web-hot-reload';

final jsModuleErrorsExtension = '.ddc.js.errors';
final jsModuleExtension = '.ddc.js';
final jsSourceMapExtension = '.ddc.js.map';
final metadataExtension = '.ddc.js.metadata';
final symbolsExtension = '.ddc.js.symbols';
final fullKernelExtension = '.ddc.full.dill';

final fesJsExtension = '.dart.lib.js';
final fesJsAlternateExtension = '.lib.js';
final fesSourceMapExtension = '.dart.lib.js.map';

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

enum ModuleStrategy { fine, coarse }

ModuleStrategy moduleStrategy(BuilderOptions options) {
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

String? _rootPackageName;

/// Returns root package name from `pubspec.yaml` in the current directory.
///
/// Caches the parsed value to [_rootPackageName]. Uses [fallbackPackageName] if
/// `pubspec.yaml` doesn't exist (such as in unit tests).
String getRootPackageName([String fallbackPackageName = '']) {
  if (_rootPackageName != null) return _rootPackageName!;
  var dir = Directory.current;
  // Search parent directories to locate the root package's pubspec.yaml
  // since tests or custom builds may be executed from nested subdirectories.
  while (true) {
    final pubspecFile = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      final lines = pubspecFile.readAsLinesSync();
      for (final line in lines) {
        // Matches 'name: <package_name>'.
        final match = RegExp(r'^name:\s*([^\s#]+)').firstMatch(line.trim());
        if (match != null) {
          _rootPackageName = match.group(1);
          return _rootPackageName!;
        }
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return _rootPackageName ??= fallbackPackageName;
}

/// Translates a Frontend Server's file paths to the equivalent path expected by
/// the build runner.
///
/// Examples:
/// - `package:foo/lib/bar.dart` to `packages/foo/bar.dart`
/// - `org-dartlang-app:///web/main.dart` to `web/main.dart`
/// - `foo.dart.lib.js` to `foo.ddc.js`
/// - `foo.lib.js` to `foo.ddc.js`
/// - `package:path/lib/path.dart.lib.js` to `packages/path/path.ddc.js`
/// - `package:root_app/lib/utils.dart.lib.js` to `lib/utils.ddc.js`
String fesToAssetPath(String sourcePath, {String? rootPackage}) {
  if (sourcePath.startsWith('/')) {
    sourcePath = sourcePath.substring(1);
  }
  if (sourcePath.startsWith('package:')) {
    sourcePath = 'packages/${sourcePath.substring('package:'.length)}';
  } else if (sourcePath.startsWith('$multiRootScheme:///')) {
    sourcePath = sourcePath.substring('$multiRootScheme:///'.length);
  }
  // Drop 'lib/' in package paths.
  sourcePath = sourcePath.replaceFirst('/lib/', '/');
  sourcePath = sourcePath
      .replaceAll(fesJsExtension, jsModuleExtension)
      .replaceAll(fesJsAlternateExtension, jsModuleExtension);
  // Re-root to 'lib/' if in the root package.
  final root = rootPackage ?? getRootPackageName();
  if (root.isNotEmpty && sourcePath.startsWith('packages/$root/')) {
    sourcePath = 'lib/${sourcePath.substring('packages/$root/'.length)}';
  }
  return sourcePath;
}
