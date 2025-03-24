// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../asset/id.dart';
import 'deps_node.dart';

/// Loads Dart source to [DepsNode]s, parsing directives and determining
/// the build phase.
class DepsNodeLoader {
  static const _ignoredSchemes = ['dart', 'dart-ext'];

  final PhaseRestrictedReader _reader;

  DepsNodeLoader(this._reader);

  Future<DepsNode> load(AssetId id) async {
    final contents = await _reader.read(id);
    if (contents.contents == null) {
      return DepsNode.missingSource(id);
    }

    final parsed =
        parseString(
          content: contents.contents!,
          throwIfDiagnostics: false,
        ).unit;

    final result = DepsNodeBuilder()..phase = contents.phase!;
    for (final directive in parsed.directives) {
      if (directive is! UriBasedDirective) continue;
      final uri = directive.uri.stringValue;
      if (uri == null) continue;
      final parsedUri = Uri.parse(uri);
      if (_ignoredSchemes.any(parsedUri.isScheme)) continue;
      final assetId = AssetId.resolve(parsedUri, from: id);
      result.deps.add(assetId);
    }
    return result.build();
  }
}

abstract class PhaseRestrictedReader {
  Future<PhaseRestrictedContents> read(AssetId id);
}

class PhaseRestrictedContents {
  final int? phase;
  final String? contents;

  PhaseRestrictedContents(this.phase, this.contents);
}
