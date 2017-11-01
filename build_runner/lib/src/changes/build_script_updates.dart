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

  /// Checks if the current running program has been updated, based on previous
  /// known digests in [_graph].
  Future<bool> hasBeenUpdated() async {
    var urisInUse = currentMirrorSystem().libraries.keys;
    return (await Future.wait(urisInUse.map(_wasUpdated)))
        .any((wasUpdated) => wasUpdated);
  }

  Future<bool> _wasUpdated(Uri uri) async {
    AssetId id;
    switch (uri.scheme) {
      case 'dart':
        // TODO: check for sdk updates!
        return false;
      case 'package':
        var parts = uri.pathSegments;
        id = new AssetId(parts[0],
            p.url.joinAll(['lib']..addAll(parts.getRange(1, parts.length))));
        break;
      case 'file':
        var relativePath = p.relative(uri.path, from: p.current);
        id = new AssetId(_rootPackage, relativePath);
        break;
      case 'data':
        // Test runner uses a `data` scheme, don't invalidate for those.
        if (uri.path.contains('package:test')) {
          return false;
        }
        continue unsupported;
      case 'http':
        // Running via `pub run`, the bin script (and relative imports of it)
        // will be loaded by uri from a server serving the bin dir.
        //
        // We turn these into asset ids pointing at the bin dir of the root
        // package.
        id =
            new AssetId(_rootPackage, p.url.join('bin', uri.path.substring(1)));
        if (!await _reader.canRead(id)) {
          _logger.info('Unrecognized asset $id inferred from http uri $uri. '
              'Falling back on full rebuild.');
          return true;
        }
        break;
      unsupported:
      default:
        _logger.info('Unsupported uri scheme `${uri.scheme}` found for '
            'library in build script, falling back on full rebuild. '
            '\nThis probably means you are running in an unsupported '
            'context, such as in an isolate or via `pub run`. Instead you '
            'should invoke this script directly like: '
            '`dart path_to_script.dart`.\n'
            'Full uri was:  $uri.');
        return true;
    }

    var node = _graph.get(id);
    if (node.lastKnownDigest == null) {
      node.lastKnownDigest = await _reader.digest(id);
      return true;
    } else {
      var currentDigest = await _reader.digest(id);
      if (node.lastKnownDigest == currentDigest) return false;
      node.lastKnownDigest = currentDigest;
      return true;
    }
  }
}

void hello() {}
