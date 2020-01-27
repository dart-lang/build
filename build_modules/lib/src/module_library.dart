// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';

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
  ///
  /// Null if this is not an importable library.
  final Set<AssetId> _deps;

  /// The "part" files for this library.
  ///
  /// Null if this is not an importable library.
  final Set<AssetId> parts;

  /// The `dart:` libraries that this library directly depends on.
  final Set<String> sdkDeps;

  /// Whether this library has a `main` function.
  final bool hasMain;

  ModuleLibrary._(this.id,
      {@required this.isEntryPoint,
      @required Set<AssetId> deps,
      @required this.parts,
      @required this.conditionalDeps,
      @required this.sdkDeps,
      @required this.hasMain})
      : _deps = deps,
        isImportable = true;

  ModuleLibrary._nonImportable(this.id)
      : isImportable = false,
        isEntryPoint = false,
        _deps = null,
        parts = null,
        conditionalDeps = null,
        sdkDeps = null,
        hasMain = false;

  factory ModuleLibrary._fromCompilationUnit(
      AssetId id, bool isEntryPoint, CompilationUnit parsed) {
    var deps = <AssetId>{};
    var parts = <AssetId>{};
    var sdkDeps = <String>{};
    var conditionalDeps = <Map<String, AssetId>>[];
    for (var directive in parsed.directives) {
      if (directive is! UriBasedDirective) continue;
      var path = (directive as UriBasedDirective).uri.stringValue;
      var uri = Uri.parse(path);
      if (uri.isScheme('dart-ext')) {
        // TODO: What should we do for native extensions?
        continue;
      }
      if (uri.scheme == 'dart') {
        sdkDeps.add(uri.path);
        continue;
      }
      var linkedId = AssetId.resolve(path, from: id);
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
      if (conditionalDirectiveConfigurations != null) {
        var conditions = <String, AssetId>{r'$default': linkedId};
        for (var condition in conditionalDirectiveConfigurations) {
          if (Uri.parse(condition.uri.stringValue).scheme == 'dart') {
            throw ArgumentError('Unsupported conditional import of '
                '`${condition.uri.stringValue}` found in $id.');
          }
          conditions[condition.name.toSource()] =
              AssetId.resolve(condition.uri.stringValue, from: id);
        }
        conditionalDeps.add(conditions);
      } else {
        deps.add(linkedId);
      }
    }
    return ModuleLibrary._(id,
        isEntryPoint: isEntryPoint,
        deps: deps,
        parts: parts,
        sdkDeps: sdkDeps,
        conditionalDeps: conditionalDeps,
        hasMain: _hasMainMethod(parsed));
  }

  /// Parse the directives from [source] and compute the library information.
  static ModuleLibrary fromSource(AssetId id, String source) {
    final isLibDir = id.path.startsWith('lib/');
    // ignore: deprecated_member_use
    final parsed = parseCompilationUnit(source,
        name: id.path, suppressErrors: true, parseFunctionBodies: false);
    // Packages within the SDK but published might have libraries that can't be
    // used outside the SDK.
    if (parsed.directives.any((d) =>
        d is UriBasedDirective &&
        d.uri.stringValue.startsWith('dart:_') &&
        id.package != 'dart_internal')) {
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
    var json = jsonDecode(encoded);

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
        hasMain: json['hasMain'] as bool);
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
      });

  List<AssetId> depsForPlatform(DartPlatform platform) {
    return _deps.followedBy(conditionalDeps.map((conditions) {
      var selectedImport = conditions[r'$default'];
      assert(selectedImport != null);
      for (var condition in conditions.keys) {
        if (condition == r'$default') continue;
        if (!condition.startsWith('dart.library.')) {
          throw UnsupportedError(
              '$condition not supported for config specific imports. Only the '
              'dart.library.<name> constants are supported.');
        }
        var library = condition.substring('dart.library.'.length);
        if (platform.supportsLibrary(library)) {
          selectedImport = conditions[condition];
          break;
        }
      }
      return selectedImport;
    })).toList();
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
    node.name.name == 'main' &&
    node.functionExpression.parameters.parameters.length <= 2);
