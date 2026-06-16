// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config_types.dart';

import 'asset_content.dart';
import 'builder_filesystem.dart';
import 'input_tracker.dart';
import 'resolver/delegating_resolver.dart';

/// A single step in the build processes.
///
/// This represents a single input and its expected and real outputs. It also
/// handles tracking of dependencies.
class BuildStepImpl implements BuildStep {
  final Resolvers? _resolvers;

  /// The primary input id for this build step.
  @override
  final AssetId inputId;

  @override
  Future<LibraryElement> get inputLibrary async {
    if (_isComplete) throw BuildStepCompletedException();
    return resolver.libraryFor(inputId);
  }

  /// The list of all outputs which are expected/allowed to be output from this
  /// step.
  @override
  final Set<AssetId> allowedOutputs;

  final InputTracker inputTracker;
  final Map<AssetId, AssetContent> outputs = {};

  final int phase;

  final BuilderFilesystem buildFilesystem;

  final ResourceManager _resourceManager;

  bool _isComplete = false;

  final void Function(Iterable<AssetId>)? _reportUnusedAssets;

  Future<Result<PackageConfig>>? _resolvedPackageConfig;

  Future<ReleasableResolver>? _resolver;

  BuildStepImpl({
    required this.inputId,
    required Iterable<AssetId> expectedOutputs,
    required this.inputTracker,
    required this.buildFilesystem,
    required this.phase,
    required Resolvers resolvers,
    required ResourceManager resourceManager,
    void Function(Iterable<AssetId>)? reportUnusedAssets,
  }) : allowedOutputs = UnmodifiableSetView(expectedOutputs.toSet()),
       _resolvers = resolvers,
       _resourceManager = resourceManager,
       _reportUnusedAssets = reportUnusedAssets;

  @override
  Future<PackageConfig> get packageConfig async {
    final resolved = _resolvedPackageConfig ??= Result.capture(
      Future.value(
        _transformToAssetUris(buildFilesystem.buildPackages.asPackageConfig),
      ),
    );

    return (await resolved).asFuture;
  }

  @override
  Resolver get resolver {
    if (_isComplete) throw BuildStepCompletedException();
    final resolvers = _resolvers;
    if (resolvers == null) {
      throw UnsupportedError('Resolvers are not available in this build.');
    }

    return DelegatingResolver(_resolver ??= resolvers.get(this));
  }

  Future<bool> _isReadable(
    AssetId id, {
    bool catchInvalidInputs = false,
    bool track = true,
  }) async {
    if (outputs.containsKey(id)) return true;
    if (track) inputTracker.add(id);
    return await buildFilesystem.isReadable(
      id,
      phase,
      catchInvalidInputs: catchInvalidInputs,
    );
  }

  @override
  Future<bool> canRead(AssetId id, {bool track = true}) async {
    if (_isComplete) throw BuildStepCompletedException();
    final isReadable = await _isReadable(
      id,
      catchInvalidInputs: true,
      track: track,
    );
    if (!isReadable) return false;

    if (buildFilesystem.buildStepPlan.isDeclaredOutput(id) &&
        !await buildFilesystem.readerWriter.canRead(id)) {
      return false;
    }

    await buildFilesystem.ensureDigest(id);
    return true;
  }

  @override
  Future<T> fetchResource<T>(Resource<T> resource) {
    if (_isComplete) throw BuildStepCompletedException();
    return _resourceManager.fetch(resource);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (_isComplete) throw BuildStepCompletedException();
    final isReadable = await _isReadable(id);
    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    if (outputs.containsKey(id)) {
      return outputs[id]!.bytes;
    }
    await buildFilesystem.ensureDigest(id);
    return buildFilesystem.readerWriter.readAsBytes(id);
  }

  @override
  Future<String> readAsString(
    AssetId id, {
    Encoding encoding = utf8,
    bool track = true,
  }) async {
    if (_isComplete) throw BuildStepCompletedException();
    final isReadable = await _isReadable(id, track: track);
    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    if (outputs.containsKey(id)) {
      return outputs[id]!.stringValue(encoding: encoding);
    }
    await buildFilesystem.ensureDigest(id);
    return buildFilesystem.readerWriter.readAsString(id, encoding: encoding);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) {
    if (_isComplete) throw BuildStepCompletedException();
    return buildFilesystem.findAssets(
      glob,
      package: inputId.package,
      phase: phase,
      trackGlob: inputTracker.addGlob,
    );
  }

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) async {
    if (_isComplete) throw BuildStepCompletedException();
    _checkOutput(id);
    outputs[id] = AssetContent.bytes(await bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> content, {
    Encoding encoding = utf8,
  }) async {
    if (_isComplete) throw BuildStepCompletedException();
    _checkOutput(id);
    outputs[id] = AssetContent.string(await content, encoding: encoding);
  }

  @override
  Future<Digest> digest(AssetId id, {bool track = true}) async {
    if (_isComplete) throw BuildStepCompletedException();
    final isReadable = await _isReadable(id, track: track);

    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    if (outputs.containsKey(id)) {
      return outputs[id]!.digest;
    }
    return buildFilesystem.ensureDigest(id);
  }

  @override
  T trackStage<T>(
    String label,
    T Function() action, {
    bool isExternal = false,
  }) => action();

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written and the
  /// [Resolver] for this build step - if any - has been released.
  Future<void> complete() async {
    _isComplete = true;
    try {
      (await _resolver)?.release();
    } catch (_) {}
  }

  /// Checks that [id] is an expected output, and throws an
  /// [InvalidOutputException] or [UnexpectedOutputException] if it's not.
  void _checkOutput(AssetId id) {
    if (!allowedOutputs.contains(id)) {
      throw UnexpectedOutputException(id, expected: allowedOutputs);
    }

    if (outputs.containsKey(id)) {
      throw InvalidOutputException(
        id,
        'This build step already wrote to `$id`. Duplicate writes to the same '
        'asset are forbidden.',
      );
    }
  }

  @override
  void reportUnusedAssets(Iterable<AssetId> assets) {
    _reportUnusedAssets?.call(assets);
  }
}

final _lib = Uri.parse('lib/');

PackageConfig _transformToAssetUris(PackageConfig config) {
  return PackageConfig([
    for (final package in config.packages)
      Package(
        package.name,
        Uri(scheme: 'asset', pathSegments: [package.name, '']),
        packageUriRoot: _lib,
        extraData: package.extraData,
        languageVersion: package.languageVersion,
      ),
  ], extraData: config.extraData);
}
