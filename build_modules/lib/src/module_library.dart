// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

import 'platform.dart';

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

  /// Deps that are imported with a conditional import.
  ///
  /// Keys are the stringified ast node for the conditional, and the default
  /// import is under the magic `$default` key.
  final List<Map<String, AssetId>> conditionalDeps;

  /// The IDs of libraries that are imported or exported by this library.
  final Set<AssetId> _deps;

  /// The "part" files for this library.
  final Set<AssetId> parts;

  /// The `dart:` libraries that this library directly depends on.
  final Set<String> sdkDeps;

  /// Whether this library has a `main` function.
  final bool hasMain;

  /// A map of the macro class names defined in this library, to the names of
  /// the public constructors for those classes.
  final Map<String, List<String>> macroConstructors;

  ModuleLibrary._(this.id,
      {required this.isEntryPoint,
      required Set<AssetId> deps,
      required this.parts,
      required this.conditionalDeps,
      required this.sdkDeps,
      required this.hasMain,
      required this.macroConstructors})
      : _deps = deps,
        isImportable = true;

  ModuleLibrary._nonImportable(this.id)
      : isImportable = false,
        isEntryPoint = false,
        _deps = const {},
        parts = const {},
        conditionalDeps = const [],
        sdkDeps = const {},
        hasMain = false,
        macroConstructors = const {};

  factory ModuleLibrary._fromCompilationUnit(
      AssetId id, bool isEntryPoint, CompilationUnit parsed) {
    var deps = <AssetId>{};
    var parts = <AssetId>{};
    var sdkDeps = <String>{};
    var conditionalDeps = <Map<String, AssetId>>[];
    for (var directive in parsed.directives) {
      if (directive is! UriBasedDirective) continue;
      var path = directive.uri.stringValue;
      if (path == null) continue;

      List<Configuration>? conditionalDirectiveConfigurations;
      if (directive is ImportDirective && directive.configurations.isNotEmpty) {
        conditionalDirectiveConfigurations = directive.configurations;
      } else if (directive is ExportDirective &&
          directive.configurations.isNotEmpty) {
        conditionalDirectiveConfigurations = directive.configurations;
      }

      var uri = Uri.parse(path);
      if (uri.isScheme('dart-ext')) {
        // TODO: What should we do for native extensions?
        continue;
      }
      if (uri.scheme == 'dart') {
        if (conditionalDirectiveConfigurations != null) {
          _checkValidConditionalImport(uri, id, directive);
        }
        sdkDeps.add(uri.path);
        continue;
      }
      var linkedId = AssetId.resolve(uri, from: id);
      if (directive is PartDirective) {
        parts.add(linkedId);
        continue;
      }

      if (conditionalDirectiveConfigurations != null) {
        var conditions = <String, AssetId>{r'$default': linkedId};
        for (var condition in conditionalDirectiveConfigurations) {
          var uriString = condition.uri.stringValue;
          var parsedUri = uriString == null ? null : Uri.parse(uriString);
          _checkValidConditionalImport(parsedUri, id, directive);
          parsedUri = parsedUri!;
          conditions[condition.name.toSource()] =
              AssetId.resolve(parsedUri, from: id);
        }
        conditionalDeps.add(conditions);
      } else {
        deps.add(linkedId);
      }
    }

    // Find all macros and record their constructors.
    var macroConstructors = <String, List<String>>{};
    for (var declaration in parsed.declarations) {
      if (declaration is ClassDeclaration && declaration.macroKeyword != null) {
        for (var member in declaration.members) {
          if (member is ConstructorDeclaration &&
              member.constKeyword != null &&
              member.name?.lexeme.startsWith('_') != true) {
            macroConstructors
                .putIfAbsent(declaration.name.lexeme, () => [])
                .add(member.name?.lexeme ?? '');
          }
        }
      }
    }

    return ModuleLibrary._(id,
        isEntryPoint: isEntryPoint,
        deps: deps,
        parts: parts,
        sdkDeps: sdkDeps,
        conditionalDeps: conditionalDeps,
        hasMain: _hasMainMethod(parsed),
        macroConstructors: macroConstructors);
  }

  static void _checkValidConditionalImport(
      Uri? parsedUri, AssetId id, UriBasedDirective node) {
    if (parsedUri == null) {
      throw ArgumentError(
          'Unsupported conditional import with non-constant uri found in $id:'
          '\n\n${node.toSource()}');
    } else if (parsedUri.scheme == 'dart') {
      throw ArgumentError(
          'Unsupported conditional import of `$parsedUri` found in $id:\n\n'
          '${node.toSource()}\n\nThis environment does not support direct '
          'conditional imports of `dart:` libraries. Instead you must create '
          'a separate library which unconditionally imports (or exports) the '
          '`dart:` library that you want to use, and conditionally import (or '
          'export) that library.');
    }
  }

  /// Parse the directives from [source] and compute the library information.
  static ModuleLibrary fromSource(AssetId id, String source) {
    final isLibDir = id.path.startsWith('lib/');
    final parsed = parseString(content: source, throwIfDiagnostics: false).unit;
    // Packages within the SDK but published might have libraries that can't be
    // used outside the SDK.
    if (parsed.directives.any((d) =>
        d is UriBasedDirective &&
        d.uri.stringValue?.startsWith('dart:_') == true &&
        id.package != 'dart_internal' &&
        id.package != 'js')) {
      return ModuleLibrary._nonImportable(id);
    }
    if (_isPart(parsed)) {
      return ModuleLibrary._nonImportable(id);
    }

    final isEntryPoint =
        (isLibDir && !id.path.startsWith('lib/src/')) || _hasMainMethod(parsed);
    return ModuleLibrary._fromCompilationUnit(id, isEntryPoint, parsed);
  }

  /// Parses the output of [serialize] back into a [ModuleLibrary].
  ///
  /// Importable libraries can be round tripped to a String. Non-importable
  /// libraries should not be printed or parsed.
  factory ModuleLibrary.deserialize(AssetId id, String encoded) {
    var json = jsonDecode(encoded) as Map<String, Object?>;

    return ModuleLibrary._(id,
        isEntryPoint: json['isEntrypoint'] as bool,
        deps: _deserializeAssetIds(json['deps'] as Iterable),
        parts: _deserializeAssetIds(json['parts'] as Iterable),
        sdkDeps: Set.of((json['sdkDeps'] as Iterable).cast<String>()),
        conditionalDeps:
            (json['conditionalDeps'] as Iterable).map((conditions) {
          return Map.of((conditions as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, AssetId.parse(v as String))));
        }).toList(),
        hasMain: json['hasMain'] as bool,
        macroConstructors: {
          for (var entry
              in (json['macroConstructors'] as Map<String, Object?>).entries)
            entry.key: List.from(entry.value as List<Object?>, growable: false)
        });
  }

  String serialize() => jsonEncode({
        'isEntrypoint': isEntryPoint,
        'deps': _deps.map((id) => id.toString()).toList(),
        'parts': parts.map((id) => id.toString()).toList(),
        'conditionalDeps': conditionalDeps
            .map((conditions) =>
                conditions.map((k, v) => MapEntry(k, v.toString())))
            .toList(),
        'sdkDeps': sdkDeps.toList(),
        'hasMain': hasMain,
        'macroConstructors': macroConstructors,
      });

  List<AssetId> depsForPlatform(DartPlatform platform) {
    AssetId depForConditions(Map<String, AssetId> conditions) {
      var selectedImport = conditions[r'$default']!;
      for (var condition in conditions.keys) {
        if (condition == r'$default') continue;
        if (!condition.startsWith('dart.library.')) {
          throw UnsupportedError(
              '$condition not supported for config specific imports. Only the '
              'dart.library.<name> constants are supported.');
        }
        var library = condition.substring('dart.library.'.length);
        if (platform.supportsLibrary(library)) {
          selectedImport = conditions[condition]!;
          break;
        }
      }
      return selectedImport;
    }

    return [
      ..._deps,
      for (var conditions in conditionalDeps) depForConditions(conditions)
    ];
  }
}

Set<AssetId> _deserializeAssetIds(Iterable serlialized) =>
    Set.from(serlialized.map((decoded) => AssetId.parse(decoded as String)));

bool _isPart(CompilationUnit dart) =>
    dart.directives.any((directive) => directive is PartOfDirective);

/// Allows two or fewer arguments to `main` so that entrypoints intended for
/// use with `spawnUri` get counted.
//
// TODO: This misses the case where a Dart file doesn't contain main(),
// but has a part that does, or it exports a `main` from another library.
bool _hasMainMethod(CompilationUnit dart) => dart.declarations.any((node) =>
    node is FunctionDeclaration &&
    node.name.lexeme == 'main' &&
    node.functionExpression.parameters != null &&
    node.functionExpression.parameters!.parameters.length <= 2);
