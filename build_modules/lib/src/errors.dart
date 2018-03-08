// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';

import 'modules.dart';

/// An [Exception] that is thrown when a worker returns an error.
abstract class _WorkerException implements Exception {
  final AssetId failedAsset;

  final String error;

  /// A message to prepend to [toString] output.
  String get message;

  _WorkerException(this.failedAsset, this.error);

  @override
  String toString() => '$message:$failedAsset\n\n$error';
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
class KernelSummaryException extends _WorkerException {
  @override
  final String message = 'Error creating kernel summary for module';

  KernelSummaryException(AssetId summaryId, String error)
      : super(summaryId, error);
}

/// An [Exception] that is thrown when there are some missing modules.
class MissingModulesException implements Exception {
  final String message;

  @override
  String toString() => message;

  MissingModulesException._(this.message);

  static Future<MissingModulesException> create(
      Module module,
      Set<AssetId> missingSources,
      List<Module> transitiveModules,
      AssetReader reader) async {
    var buffer = new StringBuffer(
        ' Unable to find modules for some sources, check the following '
        'imports:\n\n');

    var checkedSourceDependencies = <AssetId, Set<AssetId>>{};
    for (var module in transitiveModules) {
      var missingIds = module.directDependencies.intersection(missingSources);
      for (var missingId in missingIds) {
        var checkedAlready = checkedSourceDependencies.putIfAbsent(
            missingId, () => new Set<AssetId>());
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

    return new MissingModulesException._(buffer.toString());
  }
}

/// Checks if [sourceId] directly imports [missingId], and returns an error
/// message if so.
Future<String> _missingImportMessage(
    AssetId sourceId, AssetId missingId, AssetReader reader) async {
  var contents = await reader.readAsString(sourceId);
  var parsed = parseDirectives(contents, suppressErrors: true);
  var import = parsed.directives
      .where((directive) => directive is UriBasedDirective)
      .cast<UriBasedDirective>()
      .firstWhere((directive) {
    var uriString = directive.uri.stringValue;
    if (uriString.startsWith('dart:')) return false;
    var id = new AssetId.resolve(uriString, from: sourceId);
    return id == missingId;
  }, orElse: () => null);
  if (import == null) return null;
  var lineInfo = parsed.lineInfo.getLocation(import.offset);
  return '`$import` from $sourceId at $lineInfo';
}
