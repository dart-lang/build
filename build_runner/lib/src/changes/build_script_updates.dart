// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset/reader.dart';
import '../asset_graph/graph.dart';
import '../generate/options.dart';

class BuildScriptUpdates {
  final AssetGraph _graph;
  final String _rootPackage;
  final DigestAssetReader _reader;
  final _logger = new Logger('BuildScriptUpdates');

  BuildScriptUpdates(BuildOptions options, this._graph)
      : _reader = options.reader,
        _rootPackage = options.packageGraph.root.name;

  Iterable<Uri> get _urisForThisScript => currentMirrorSystem().libraries.keys;

  /// Checks if the current running program has been updated, based on previous
  /// known digests in [_graph].
  Future<bool> hasBeenUpdated() async {
    return (await Future.wait(_urisForThisScript.map(_wasUpdated)))
        .any((wasUpdated) => wasUpdated);
  }

  /// Records initial digests for all imports in the current program.
  Future<Null> recordInitialDigests() async {
    await Future.wait(_urisForThisScript.map((uri) async {
      try {
        var id = _idForUri(uri);
        // Returns null for uris we don't care about, such as dart: uris and
        // certain data: uris.
        if (id == null) return;
        var node = _graph.get(id);
        if (node == null) {
          _logger.warning('$id was not found in the asset graph, incremental '
              'builds will not work.\n This probably means you don\'t have '
              'your dependencies specified fully in your pubspec.yaml.');
          return;
        }
        if (node.lastKnownDigest == null) {
          node.lastKnownDigest = await _reader.digest(id);
        }
      } on ArgumentError catch (e) {
        _logger.warning(
            'Unable to record digests for build script sources, '
            'incremental builds will not work.',
            e);
      }
    }));
  }

  /// Attempts to return an [AssetId] for [uri].
  ///
  /// Returns `null` if the uri should be ignored, or throws an [ArgumentError]
  /// if the [uri] is not recognized.
  AssetId _idForUri(Uri uri) {
    switch (uri.scheme) {
      case 'dart':
        // TODO: check for sdk updates!
        break;
      case 'package':
        var parts = uri.pathSegments;
        return new AssetId(parts[0],
            p.url.joinAll(['lib']..addAll(parts.getRange(1, parts.length))));
      case 'file':
        var relativePath = p.relative(uri.path, from: p.current);
        return new AssetId(_rootPackage, relativePath);
      case 'data':
        // Test runner uses a `data` scheme, don't invalidate for those.
        if (uri.path.contains('package:test')) break;
        continue unsupported;
      case 'http':
        // Running via `pub run`, the bin script (and relative imports of it)
        // will be loaded by uri from a server serving the bin dir.
        //
        // We turn these into asset ids pointing at the bin dir of the root
        // package.
        return new AssetId(
            _rootPackage, p.url.join('bin', uri.path.substring(1)));
      unsupported:
      default:
        throw new ArgumentError(
            'Unsupported uri scheme `${uri.scheme}` found for '
            'library in build script.\n'
            'This probably means you are running in an unsupported '
            'context, such as in an isolate.\n'
            'Full uri was: $uri.');
    }
    return null;
  }

  /// Checks whether [uri] has been updated.
  ///
  /// If it can't tell due to an unsupported uri, then this always returns
  /// `true`.
  Future<bool> _wasUpdated(Uri uri) async {
    AssetId id;
    try {
      id = _idForUri(uri);
      // `null` but no error is a signal to skip this uri.
      if (id == null) return false;
    } on ArgumentError catch (e, _) {
      _logger.warning(
          'Unable to check build script for updates, falling back on full '
          'rebuild.',
          e);
      return true;
    }

    if (!await _reader.canRead(id)) {
      _logger.info('Unable to read asset $id, falling back on full rebuild.');
      return true;
    }

    var node = _graph.get(id);
    if (node == null) {
      _logger.warning('$id was not found in the asset graph, falling back on '
          'full rebuild.\n This probably means you don\'t have your '
          'dependencies specified fully in your pubspec.yaml.');
      return true;
    }
    if (node.lastKnownDigest == null) {
      // This could happen if a new import was added, or we weren't able to
      // initially compute the last known digest.
      return true;
    } else {
      var currentDigest = await _reader.digest(id);
      if (node.lastKnownDigest == currentDigest) return false;
      return true;
    }
  }
}
