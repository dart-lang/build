// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../asset/id.dart';
import 'asset_deps.dart';
import 'phased_reader.dart';
import 'phased_value.dart';

/// Loads Dart source assets to [PhasedValue]s of [AssetDeps].
class AssetDepsLoader {
  static const _ignoredSchemes = ['dart', 'dart-ext'];

  final PhasedReader _reader;

  AssetDepsLoader(this._reader);

  /// The phase that this loader is reading build state at.
  int get phase => _reader.phase;

  /// Reads [id]
  ///
  /// If [id] will be generated at a phase equal to or after [phase], the
  /// result is incomplete, with an expirey phase.
  Future<PhasedValue<AssetDeps>> load(AssetId id) async {
    final content = await _reader.readPhased(id);

    return PhasedValue((b) {
      b.values.addAll(content.values.map((content) => _parse(id, content)));
    });
  }

  /// Parses directives in [content] to return an [AssetDeps].
  ExpiringValue<AssetDeps> _parse(AssetId id, ExpiringValue<String> content) {
    final result =
        ExpiringValueBuilder<AssetDeps>()..expiresAfter = content.expiresAfter;

    final parsed =
        parseString(content: content.value, throwIfDiagnostics: false).unit;

    final depsNodeBuilder = AssetDepsBuilder();

    for (final directive in parsed.directives) {
      if (directive is! UriBasedDirective) continue;
      final uri = directive.uri.stringValue;
      if (uri == null) continue;
      final parsedUri = Uri.parse(uri);
      if (_ignoredSchemes.any(parsedUri.isScheme)) continue;
      final assetId = AssetId.resolve(parsedUri, from: id);
      depsNodeBuilder.deps.add(assetId);
    }

    result.value = depsNodeBuilder.build();
    return result.build();
  }
}
