// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/src/logging/logging.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'asset_change.dart';
import 'node_watcher.dart';

typedef PackageNodeWatcher _Strategy(PackageNode node);
PackageNodeWatcher _default(PackageNode node) => new PackageNodeWatcher(node);

/// Allows watching an entire graph of packages to schedule rebuilds.
class PackageGraphWatcher {
  // TODO: Consider pulling logging out and providing hooks instead.
  final Logger _logger;
  final _Strategy _strategy;
  final PackageGraph _graph;

  /// Creates a new watcher for a [PackageGraph].
  ///
  /// May optionally specify a [watch] strategy, otherwise will attempt a
  /// reasonable default based on the current platform.
  PackageGraphWatcher(
    this._graph, {
    Logger logger,
    PackageNodeWatcher watch(PackageNode node),
  })
      : _logger = logger ?? new Logger('build_runner'),
        _strategy = watch ?? _default;

  /// Returns a stream of records for assets that changed in the package graph.
  Stream<AssetChange> watch() {
    StreamController<AssetChange> controller;
    List<StreamSubscription> subscriptions;
    controller = new StreamController<AssetChange>(
      sync: true,
      onListen: () {
        subscriptions = logTimedSync(
          _logger,
          'Setting up file watchers',
          () => _watch(controller),
        );
      },
      onCancel: () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  List<StreamSubscription> _watch(StreamSink<AssetChange> sink) {
    final subscriptions = <StreamSubscription>[];
    final absolutePaths = _absolutePaths();
    _graph.allPackages.forEach((name, node) {
      final nestedPackages = _nestedPaths(absolutePaths, node);
      subscriptions.add(_strategy(node).watch().listen((event) {
        // TODO: Consider a faster filtering strategy.
        final absolutePath = p.join(absolutePaths[node], event.id.path);
        _logger.fine('Setting up watcher at $absolutePaths');
        if (nestedPackages.any((path) => p.isWithin(path, absolutePath))) {
          return;
        }
        _logger.finest(
            'Got ${event.type} event for "${event.id.uri} in ${node.path}');
        sink.add(event);
      }));
    });
    return subscriptions;
  }

  // Returns a mapping of node -> absolute path on disk.
  Map<PackageNode, String> _absolutePaths() {
    return new Map<PackageNode, String>.fromIterable(
      _graph.allPackages.values,
      value: (PackageNode node) => node.path,
    );
  }

  // Returns a set of all packages that are "nested" within a node.
  //
  // This allows the watcher to optimize and avoid
  List<String> _nestedPaths(Map<PackageNode, String> paths, PackageNode node) {
    final absolutePath = paths[node];
    return paths.values.where((path) {
      return path != absolutePath && path.startsWith(absolutePath);
    }).toList();
  }
}
