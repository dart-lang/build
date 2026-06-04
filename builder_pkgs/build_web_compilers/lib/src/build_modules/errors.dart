// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';

import 'module_library.dart';
import 'module_library_builder.dart';
import 'modules.dart';
import 'platform.dart';

/// An [Exception] that is thrown when a worker returns an error.
abstract class _WorkerException implements Exception {
  final AssetId failedAsset;

  final String error;

  /// A message to prepend to [toString] output.
  String get message;

  _WorkerException(this.failedAsset, this.error);

  @override
  String toString() => '$message:$failedAsset\n\nResponse:$error\n';
}

/// An [Exception] that is thrown when the analyzer fails to create a summary.
class AnalyzerSummaryException extends _WorkerException {
  @override
  final String message = 'Error creating summary for module';

  AnalyzerSummaryException(super.summaryId, super.error);
}

/// An [Exception] that is thrown when the common frontend fails to create a
/// kernel summary.
class KernelException extends _WorkerException {
  @override
  final String message = 'Error creating kernel summary for module';

  KernelException(super.summaryId, super.error);
}

/// An [Exception] that is thrown when there are some missing modules.
class MissingModulesException implements Exception {
  final String message;

  @override
  String toString() => message;

  MissingModulesException._(this.message);

  static Future<MissingModulesException> create(
    Set<AssetId> missingSources,
    Iterable<Module> transitiveModules,
    AssetReader reader,
  ) async {
    final buffer = StringBuffer('''
Unable to find modules for some sources, this is usually the result of either a
bad import, a missing dependency in a package (or possibly a dev_dependency
needs to move to a real dependency), or a build failure (if importing a
generated file).

Please check the following imports:\n
''');

    final checkedSourceDependencies = <AssetId, Set<AssetId>>{};
    for (final module in transitiveModules) {
      final missingIds = module.directDependencies.intersection(missingSources);
      for (final missingId in missingIds) {
        final checkedAlready = checkedSourceDependencies.putIfAbsent(
          missingId,
          () => <AssetId>{},
        );
        for (final sourceId in module.sources) {
          if (checkedAlready.contains(sourceId)) {
            continue;
          }
          checkedAlready.add(sourceId);
          final message = await _missingImportMessage(
            sourceId,
            missingId,
            reader,
          );
          if (message != null) buffer.writeln(message);
        }
      }
    }

    return MissingModulesException._(buffer.toString());
  }
}

/// Checks if [sourceId] directly imports [missingId], and returns an error
/// message if so.
Future<String?> _missingImportMessage(
  AssetId sourceId,
  AssetId missingId,
  AssetReader reader,
) async {
  final contents = await reader.readAsString(sourceId);
  final parsed = parseString(content: contents, throwIfDiagnostics: false).unit;
  final import = parsed.directives
      .whereType<UriBasedDirective>()
      .firstWhereOrNull((directive) {
        final uris = <String?>[
          directive.uri.stringValue,
          // Conditional imports are represented as NamespaceDirectives.
          if (directive is NamespaceDirective)
            for (final config in directive.configurations)
              config.uri.stringValue,
        ];

        for (final uriString in uris) {
          if (uriString == null) continue;
          if (uriString.startsWith('dart:')) continue;

          try {
            final id = AssetId.resolve(Uri.parse(uriString), from: sourceId);
            if (id == missingId) return true;
          } on FormatException {
            // Ignore format exceptions since we're assembling an error string.
          }
        }
        return false;
      });
  if (import == null) return null;
  final lineInfo = parsed.lineInfo.getLocation(import.offset);
  return '`$import` from $sourceId at $lineInfo';
}

/// An [Exception] that is thrown when there are some unsupported modules.
class UnsupportedModules implements Exception {
  final Set<Module> unsupportedModules;

  UnsupportedModules(this.unsupportedModules);

  Stream<ModuleLibrary> exactLibraries(AssetReader reader) async* {
    for (final module in unsupportedModules) {
      for (final source in module.sources) {
        final libraryId = source.changeExtension(moduleLibraryExtension);
        ModuleLibrary library;
        if (await reader.canRead(libraryId)) {
          library = ModuleLibrary.deserialize(
            libraryId,
            await reader.readAsString(libraryId),
          );
        } else {
          // A missing .module.library file indicates a part file, which can't
          // have import statements, so we just skip them.
          continue;
        }
        if (library.sdkDeps.any(
          (lib) => !module.platform.supportsLibrary(lib),
        )) {
          yield library;
        }
      }
    }
  }

  Future<String> formattedUnsupportedMessage(
    String compilerName,
    AssetId entrypoint,
    AssetReader reader,
  ) async {
    final buffer = StringBuffer(
      'Skipping compiling $entrypoint with $compilerName '
      'because some of its\n'
      'transitive libraries have sdk dependencies that are not supported on '
      'this platform:\n\n',
    );

    final platform = unsupportedModules.first.platform;
    for (final module in unsupportedModules) {
      for (final source in module.sources) {
        final libraryId = source.changeExtension(moduleLibraryExtension);
        if (!await reader.canRead(libraryId)) continue;
        final library = ModuleLibrary.deserialize(
          libraryId,
          await reader.readAsString(libraryId),
        );
        final unsupportedSdkDeps =
            library.sdkDeps
                .where((lib) => !platform.supportsLibrary(lib))
                .toList();
        if (unsupportedSdkDeps.isEmpty) continue;

        final targetAssetId = library.id.dartAssetId;
        final path = await _findImportPath(
          entrypoint,
          targetAssetId,
          platform,
          reader,
        );
        final suffix =
            ' (which imports '
            '${unsupportedSdkDeps.map((d) => 'dart:$d').join(', ')}'
            ')';
        if (path != null) {
          buffer.writeln('${path.toDisplayString}$suffix');
        } else {
          buffer.writeln('${targetAssetId.toDisplayString}$suffix');
        }
      }
    }
    return buffer.toString();
  }

  @override
  String toString() =>
      'Some modules contained libraries that were incompatible '
      'with the current platform.';
}

Future<List<AssetId>?> _findImportPath(
  AssetId start,
  AssetId target,
  DartPlatform platform,
  AssetReader reader,
) async {
  final queue = Queue<AssetId>()..add(start);
  final visited = {start};
  final parents = <AssetId, AssetId>{};

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == target) {
      final path = <AssetId>[];
      var curr = target;
      while (curr != start) {
        path.add(curr);
        curr = parents[curr]!;
      }
      path.add(start);
      return path.reversed.toList();
    }

    final libraryId = current.changeExtension(moduleLibraryExtension);
    if (!await reader.canRead(libraryId)) continue;
    final library = ModuleLibrary.deserialize(
      libraryId,
      await reader.readAsString(libraryId),
    );
    for (final dep in library.depsForPlatform(platform)) {
      if (visited.add(dep)) {
        parents[dep] = current;
        queue.add(dep);
      }
    }
  }
  return null;
}

extension on AssetId {
  AssetId get dartAssetId =>
      AssetId(package, path.replaceFirst(moduleLibraryExtension, '.dart'));

  String get toDisplayString {
    if (path.startsWith('lib/')) {
      return 'package:$package/${path.substring(4)}';
    }
    return toString();
  }
}

extension on Iterable<AssetId> {
  String get toDisplayString => map((id) => id.toDisplayString).join(' -> ');
}
