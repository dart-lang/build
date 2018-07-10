// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';

/// A Dart library within a module.
///
/// Modules can be computed based on library dependencies (imports and exports)
/// and parts.
class ModuleLibrary {
  /// The AssetId of the original Dart source file.
  final AssetId id;

  /// Whether this library can be imported.
  ///
  /// This will be false if the source file is a "part of", or imports code that
  /// can't be used outside the SDK.
  final bool isImportable;

  /// Whether this library is an entrypoint.
  ///
  /// True if the library is in `lib/` but not `lib/src`, or if it is outside of
  /// `lib/` and contains a `main` method. Always false if this is not an
  /// importable library.
  final bool isEntryPoint;

  /// The IDs of libraries that are imported or exported by this library.
  ///
  /// Null if this is not an importable library.
  final Set<AssetId> deps;

  /// The "part" files for this library.
  ///
  /// Null if this is not an importable library.
  final Set<AssetId> parts;

  ModuleLibrary._(this.id,
      {@required this.isEntryPoint, @required this.deps, @required this.parts})
      : isImportable = true;

  ModuleLibrary._nonImportable(this.id)
      : isImportable = false,
        isEntryPoint = false,
        deps = null,
        parts = null;

  factory ModuleLibrary._fromCompilationUnit(
      AssetId id, bool isEntryPoint, CompilationUnit parsed) {
    var deps = new Set<AssetId>();
    var parts = new Set<AssetId>();
    for (var directive in parsed.directives) {
      if (directive is! UriBasedDirective) continue;
      var path = (directive as UriBasedDirective).uri.stringValue;
      if (Uri.parse(path).scheme == 'dart') continue;
      var linkedId = new AssetId.resolve(path, from: id);
      if (linkedId == null) continue;
      if (directive is PartDirective) {
        parts.add(linkedId);
        continue;
      }

      List<Configuration> conditionalDirectiveConfigurations;

      if (directive is ImportDirective && directive.configurations.isNotEmpty) {
        conditionalDirectiveConfigurations = directive.configurations;
      } else if (directive is ExportDirective &&
          directive.configurations.isNotEmpty) {
        conditionalDirectiveConfigurations = directive.configurations;
      }
      deps.add(linkedId);
      if (conditionalDirectiveConfigurations != null) {
        deps.addAll(conditionalDirectiveConfigurations
            .map((c) => Uri.parse(c.uri.stringValue))
            .where((u) => u.scheme != 'dart')
            .map((u) => new AssetId.resolve(u.toString(), from: id)));
      }
    }
    return new ModuleLibrary._(id,
        isEntryPoint: isEntryPoint, deps: deps, parts: parts);
  }

  /// Parse the directives from [source] and compute the library information.
  static ModuleLibrary fromSource(AssetId id, String source) {
    final isLibDir = id.path.startsWith('lib/');
    final parsed = isLibDir
        ? parseDirectives(source, name: id.path, suppressErrors: true)
        : parseCompilationUnit(source,
            name: id.path, suppressErrors: true, parseFunctionBodies: false);
    // Packages within the SDK but published might have libraries that can't be
    // used outside the SDK.
    if (parsed.directives.any((d) =>
        d is UriBasedDirective &&
        d.uri.stringValue.startsWith('dart:_') &&
        id.package != 'dart_internal')) {
      return new ModuleLibrary._nonImportable(id);
    }
    if (_isPart(parsed)) {
      return new ModuleLibrary._nonImportable(id);
    }

    final isEntryPoint =
        (isLibDir && !id.path.startsWith('lib/src/')) || _hasMainMethod(parsed);
    return new ModuleLibrary._fromCompilationUnit(id, isEntryPoint, parsed);
  }

  /// Parses the output of [toString] back into a [ModuleLibrary].
  ///
  /// Importable libraries can be round tripped to a String. Non-importable
  /// libraries should not be printed or parsed.
  static ModuleLibrary parse(String encoded) {
    final lines = encoded.split('\n');
    final id = new AssetId.parse(lines.first);
    final isEntryPoint = lines[1] == 'true';
    final separator = lines.indexOf('');
    final deps =
        lines.sublist(2, separator).map((l) => new AssetId.parse(l)).toSet();
    final parts = lines
        .sublist(separator + 1)
        .where((l) => l.isNotEmpty)
        .map((l) => new AssetId.parse(l))
        .toSet();
    return new ModuleLibrary._(id,
        isEntryPoint: isEntryPoint, deps: deps, parts: parts);
  }

  @override
  String toString() => '$id\n'
      '${isEntryPoint ? 'true' : 'false'}\n'
      '${deps.join('\n')}\n'
      '\n'
      '${parts.join('\n')}\n';
}

bool _isPart(CompilationUnit dart) =>
    dart.directives.any((directive) => directive is PartOfDirective);

bool _hasMainMethod(CompilationUnit dart) => dart.declarations.any((node) =>
    node is FunctionDeclaration &&
    node.name.name == 'main' &&
    node.functionExpression.parameters.parameters.length <= 2);
