// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';

import 'clause_reader.dart';
import 'contract_collector.dart';
import 'source_edits.dart';

/// Weaves executable checks for contract annotations into Dart source.
class ContractWeaver {
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
    _addContractImports(unit, edits);
    return _format(edits.apply());
  }

  /// Adds an import for each `@ContractImport` on the library directive or a
  /// top level declaration of [unit].
  ///
  /// Clauses are strings until they are woven, so a clause can use a library,
  /// typically for an extension member, that the original cannot import
  /// without the import being reported as unused. Cofoja has the same
  /// annotation.
  void _addContractImports(CompilationUnit unit, SourceEdits edits) {
    final reader = ClauseReader(edits.source);
    final imported = {
      for (final directive in unit.directives.whereType<ImportDirective>())
        directive.uri.stringValue,
    };
    final uris = <String>{
      for (final directive in unit.directives)
        ...reader.contractImports(directive.metadata),
      for (final declaration in unit.declarations)
        ...reader.contractImports(declaration.metadata),
    }.difference(imported);
    if (uris.isEmpty) return;
    if (unit.directives.any((d) => d is PartOfDirective)) {
      throw const FormatException(
        '@ContractImport must be in the library, not in a part.',
      );
    }

    edits.insert(
      _importOffset(unit),
      [for (final uri in uris) "import '$uri';\n"].join(),
    );
  }

  /// Where an import can be inserted into [unit]: before its first import,
  /// export or part directive, or else after its library directive.
  static int _importOffset(CompilationUnit unit) {
    for (final directive in unit.directives) {
      if (directive is! LibraryDirective) return directive.offset;
    }
    final library = unit.directives.whereType<LibraryDirective>().firstOrNull;
    return library == null ? 0 : library.end;
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
