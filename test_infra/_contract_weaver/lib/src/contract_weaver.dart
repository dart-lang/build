// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dart_style/dart_style.dart';

import 'contract_collector.dart';
import 'contract_import_rule.dart';
import 'source_edits.dart';

/// Weaves executable checks for contract annotations into Dart source.
class ContractWeaver {
  ContractWeaver({Iterable<ContractImportRule> importRules = const []})
    : importRules = importRules.toBuiltList();

  final BuiltList<ContractImportRule> importRules;

  /// [source] with its contracts woven in, or [source] unchanged if it has
  /// none.
  ///
  /// Throws [FormatException] if [source] does not parse or has a malformed
  /// contract.
  String weave(String source) {
    final parseResult = parseString(content: source, throwIfDiagnostics: false);
    if (parseResult.errors.isNotEmpty) {
      final messages = parseResult.errors.map((e) => e.message).join('\n');
      throw FormatException('Source has parse errors:\n$messages');
    }
    final unit = parseResult.unit;

    final edits = SourceEdits(source);
    unit.accept(ContractCollector(edits));
    if (edits.isEmpty) return source;

    return _format(_addImports(unit, edits.apply()));
  }

  /// [woven] with the imports that [importRules] call for.
  String _addImports(CompilationUnit unit, String woven) {
    // A library that already imports the target does not need it again. The
    // existing import is often relative where the rule is absolute, so compare
    // file names: importing two libraries of the same name is rare, and getting
    // it wrong fails visibly as an undefined name in the woven copy.
    final importedFileNames = {
      for (final directive in unit.directives.whereType<ImportDirective>())
        if (directive.uri.stringValue case final uri?) uri.split('/').last,
    };

    var result = woven;
    for (final rule in importRules) {
      if (importedFileNames.contains(rule.import.split('/').last)) continue;
      if (!rule.markers.any(result.contains)) continue;
      final firstImport = result.indexOf('import ');
      if (firstImport == -1) continue;
      result =
          '${result.substring(0, firstImport)}'
          "import '${rule.import}';\n"
          '${result.substring(firstImport)}';
    }
    return result;
  }

  String _format(String woven) {
    try {
      return DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(woven);
    } catch (e) {
      throw FormatException(
        'Failed to format woven code: $e\n'
        'Woven code was:\n$woven',
      );
    }
  }
}
