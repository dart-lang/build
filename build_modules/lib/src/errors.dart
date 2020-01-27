// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';

import 'module_library.dart';
import 'module_library_builder.dart';
import 'modules.dart';

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

  AnalyzerSummaryException(AssetId summaryId, String error)
      : super(summaryId, error);
}

/// An [Exception] that is thrown when the common frontend fails to create a
/// kernel summary.
class KernelException extends _WorkerException {
  @override
  final String message = 'Error creating kernel summary for module';

  KernelException(AssetId summaryId, String error) : super(summaryId, error);
}

/// An [Exception] that is thrown when there are some missing modules.
class MissingModulesException implements Exception {
  final String message;

  @override
  String toString() => message;

  MissingModulesException._(this.message);

  static Future<MissingModulesException> create(Set<AssetId> missingSources,
      Iterable<Module> transitiveModules, AssetReader reader) async {
    var buffer = StringBuffer('''
Unable to find modules for some sources, this is usually the result of either a
bad import, a missing dependency in a package (or possibly a dev_dependency
needs to move to a real dependency), or a build failure (if importing a
generated file).

Please check the following imports:\n
''');

    var checkedSourceDependencies = <AssetId, Set<AssetId>>{};
    for (var module in transitiveModules) {
      var missingIds = module.directDependencies.intersection(missingSources);
      for (var missingId in missingIds) {
        var checkedAlready =
            checkedSourceDependencies.putIfAbsent(missingId, () => <AssetId>{});
        for (var sourceId in module.sources) {
          if (checkedAlready.contains(sourceId)) {
            continue;
          }
          checkedAlready.add(sourceId);
          var message =
              await _missingImportMessage(sourceId, missingId, reader);
          if (message != null) buffer.writeln(message);
        }
      }
    }

    return MissingModulesException._(buffer.toString());
  }
}

/// Checks if [sourceId] directly imports [missingId], and returns an error
/// message if so.
Future<String> _missingImportMessage(
    AssetId sourceId, AssetId missingId, AssetReader reader) async {
  var contents = await reader.readAsString(sourceId);
  // ignore: deprecated_member_use
  var parsed = parseDirectives(contents, suppressErrors: true);
  var import =
      parsed.directives.whereType<UriBasedDirective>().firstWhere((directive) {
    var uriString = directive.uri.stringValue;
    if (uriString.startsWith('dart:')) return false;
    var id = AssetId.resolve(uriString, from: sourceId);
    return id == missingId;
  }, orElse: () => null);
  if (import == null) return null;
  var lineInfo = parsed.lineInfo.getLocation(import.offset);
  return '`$import` from $sourceId at $lineInfo';
}

/// An [Exception] that is thrown when there are some unsupported modules.
class UnsupportedModules implements Exception {
  final Set<Module> unsupportedModules;

  UnsupportedModules(this.unsupportedModules);

  Stream<ModuleLibrary> exactLibraries(AssetReader reader) async* {
    for (var module in unsupportedModules) {
      for (var source in module.sources) {
        var libraryId = source.changeExtension(moduleLibraryExtension);
        ModuleLibrary library;
        if (await reader.canRead(libraryId)) {
          library = ModuleLibrary.deserialize(
              libraryId, await reader.readAsString(libraryId));
        } else {
          // A missing .module.library file indicates a part file, which can't
          // have import statements, so we just skip them.
          continue;
        }
        if (library.sdkDeps
            .any((lib) => !module.platform.supportsLibrary(lib))) {
          yield library;
        }
      }
    }
  }

  @override
  String toString() =>
      'Some modules contained libraries that were incompatible '
      'with the current platform.';
}
