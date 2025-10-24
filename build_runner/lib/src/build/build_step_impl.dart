// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config_types.dart';

import 'input_tracker.dart';
import 'library_cycle_graph/phased_reader.dart';
import 'run_builder.dart';
import 'single_step_reader_writer.dart';

/// A single step in the build processes.
///
/// This represents a single input and its expected and real outputs. It also
/// handles tracking of dependencies.
class BuildStepImpl implements BuildStep {
  final Resolvers? _resolvers;
  final StageTracker _stageTracker;

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

  /// The result of any writes which are starting during this step.
  final _writeResults = <Future<Result<void>>>[];

  final _writtenAssets = <AssetId>{};

  final SingleStepReaderWriter _readerWriter;

  final ResourceManager _resourceManager;

  bool _isComplete = false;

  final void Function(Iterable<AssetId>)? _reportUnusedAssets;

  final Future<PackageConfig> Function() _resolvePackageConfig;
  Future<Result<PackageConfig>>? _resolvedPackageConfig;

  BuildStepImpl(
    this.inputId,
    Iterable<AssetId> expectedOutputs,
    this._readerWriter,
    this._resolvers,
    this._resourceManager,
    this._resolvePackageConfig, {
    StageTracker? stageTracker,
    void Function(Iterable<AssetId>)? reportUnusedAssets,
  }) : allowedOutputs = UnmodifiableSetView(expectedOutputs.toSet()),
       _stageTracker = stageTracker ?? NoOpStageTracker.instance,
       _reportUnusedAssets = reportUnusedAssets;

  InputTracker get inputTracker => _readerWriter.inputTracker;

  @override
  Future<PackageConfig> get packageConfig async {
    final resolved =
        _resolvedPackageConfig ??= Result.capture(_resolvePackageConfig());

    return (await resolved).asFuture;
  }

  @override
  Resolver get resolver {
    if (_isComplete) throw BuildStepCompletedException();
    final resolvers = _resolvers;
    if (resolvers == null) {
      throw UnsupportedError('Resolvers are not available in this build.');
    }

    return _DelayedResolver(_resolver ??= resolvers.get(this));
  }

  Future<ReleasableResolver>? _resolver;

  /// A reader for assets that additionally provides information about when an
  /// asset was generated or will be generated.
  PhasedReader get phasedReader => _readerWriter;

  @override
  Future<bool> canRead(AssetId id) {
    if (_isComplete) throw BuildStepCompletedException();
    return _readerWriter.canRead(id);
  }

  @override
  Future<T> fetchResource<T>(Resource<T> resource) {
    if (_isComplete) throw BuildStepCompletedException();
    return _resourceManager.fetch(resource);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    if (_isComplete) throw BuildStepCompletedException();
    return _readerWriter.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) {
    if (_isComplete) throw BuildStepCompletedException();
    return _readerWriter.readAsString(id, encoding: encoding);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) {
    if (_isComplete) throw BuildStepCompletedException();
    return _readerWriter.assetFinder.find(glob, package: inputId.package);
  }

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) {
    if (_isComplete) throw BuildStepCompletedException();
    _checkOutput(id);
    final done = _futureOrWrite(
      bytes,
      (List<int> b) => _readerWriter.writeAsBytes(id, b),
    );
    _writeResults.add(Result.capture(done));
    return done;
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> content, {
    Encoding encoding = utf8,
  }) {
    if (_isComplete) throw BuildStepCompletedException();
    _checkOutput(id);
    final done = _futureOrWrite(
      content,
      (String c) => _readerWriter.writeAsString(id, c, encoding: encoding),
    );
    _writeResults.add(Result.capture(done));
    return done;
  }

  @override
  Future<Digest> digest(AssetId id) {
    if (_isComplete) throw BuildStepCompletedException();
    return _readerWriter.digest(id);
  }

  @override
  T trackStage<T>(
    String label,
    T Function() action, {
    bool isExternal = false,
  }) => _stageTracker.trackStage(label, action, isExternal: isExternal);

  Future<void> _futureOrWrite<T>(
    FutureOr<T> content,
    Future<void> Function(T content) write,
  ) => (content is Future<T>) ? content.then(write) : write(content);

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written and the
  /// [Resolver] for this build step - if any - has been released.
  Future<void> complete() async {
    _isComplete = true;
    await Future.wait(_writeResults.map(Result.release));
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

    if (!_writtenAssets.add(id)) {
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

class _DelayedResolver implements Resolver {
  final Future<Resolver> _delegate;

  _DelayedResolver(this._delegate);

  @override
  Future<bool> isLibrary(AssetId assetId) async =>
      (await _delegate).isLibrary(assetId);

  @override
  Stream<LibraryElement> get libraries {
    final completer = StreamCompleter<LibraryElement>();
    _delegate.then((r) => completer.setSourceStream(r.libraries));
    return completer.stream;
  }

  @override
  Future<AstNode?> astNodeFor(
    Fragment fragment, {
    bool resolve = false,
  }) async => (await _delegate).astNodeFor(fragment, resolve: resolve);

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async => (await _delegate).compilationUnitFor(
    assetId,
    allowSyntaxErrors: allowSyntaxErrors,
  );

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async => (await _delegate).libraryFor(
    assetId,
    allowSyntaxErrors: allowSyntaxErrors,
  );

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) async =>
      (await _delegate).findLibraryByName(libraryName);

  @override
  Future<AssetId> assetIdForElement(Element element) async =>
      (await _delegate).assetIdForElement(element);
}
