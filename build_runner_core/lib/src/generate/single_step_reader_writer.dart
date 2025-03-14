// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import 'input_tracker.dart';
import 'phase.dart';

/// Builds an asset.
typedef AssetBuilder = Future<void> Function(AssetId);

/// Builds a "glob node": all assets matching a glob.
///
/// The node must have type [NodeType.glob].
typedef GlobNodeBuilder = Future<void> Function(AssetId);

/// Describes if and how a [SingleStepReaderWriter] should read an [AssetId].
class Readability {
  final bool canRead;
  final bool inSamePhase;

  const Readability({required this.canRead, required this.inSamePhase});

  /// Determines readability for a node written in a previous build phase, which
  /// means that [ownOutput] is impossible.
  factory Readability.fromPreviousPhase(bool readable) =>
      readable ? Readability.readable : Readability.notReadable;

  static const Readability notReadable = Readability(
    canRead: false,
    inSamePhase: false,
  );
  static const Readability readable = Readability(
    canRead: true,
    inSamePhase: false,
  );
  static const Readability ownOutput = Readability(
    canRead: true,
    inSamePhase: true,
  );
}

/// `SingleStepReaderWriter`'s view on the currently-running build.
class RunningBuild {
  final PackageGraph packageGraph;
  final TargetGraph targetGraph;
  final AssetGraph assetGraph;
  final AssetBuilder nodeBuilder;
  final GlobNodeBuilder globNodeBuilder;

  RunningBuild({
    required this.packageGraph,
    required this.targetGraph,
    required this.assetGraph,
    required this.nodeBuilder,
    required this.globNodeBuilder,
  });
}

/// `SingleStepReaderWriter`'s view on the currently-running build step.
class RunningBuildStep {
  final int phaseNumber;
  final BuildPhase buildPhase;
  final String primaryPackage;

  RunningBuildStep({
    required this.phaseNumber,
    required this.buildPhase,
    required this.primaryPackage,
  });
}

/// If there is no build currently running, state to fake it for testing.
class FakeRunningBuildStep {
  /// If set, `SingleStepReaderWriter` acts as if running in a build step where
  /// `startingAssets` are available from previous phase(s).
  final Set<AssetId>? startingAssets;

  FakeRunningBuildStep({required this.startingAssets});
}

/// An [AssetReader] with a lifetime equivalent to that of a single step in a
/// build.
///
/// A step is a single Builder and primary input (or package for package
/// builders) combination.
///
/// Limits reads to the assets which are sources or were generated by previous
/// phases.
///
/// Tracks the assets and globs read during this step for input dependency
/// tracking.
class SingleStepReaderWriter extends AssetReader
    implements AssetReaderState, AssetReaderWriter {
  @override
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  final RunningBuild? _runningBuild;
  final RunningBuildStep? _runningBuildStep;
  final FakeRunningBuildStep? _fakeRunningBuildStep;

  final AssetReaderWriter _delegate;

  final InputTracker inputTracker;

  /// The assets written via [writeAsString] or [writeAsBytes].
  final Set<AssetId> assetsWritten;

  SingleStepReaderWriter({
    required RunningBuild? runningBuild,
    required RunningBuildStep? runningBuildStep,
    FakeRunningBuildStep? fakeRunningBuildStep,
    required AssetReaderWriter readerWriter,
    required this.inputTracker,
    required this.assetsWritten,
  }) : _runningBuild = runningBuild,
       _runningBuildStep = runningBuildStep,
       _fakeRunningBuildStep = fakeRunningBuildStep,
       _delegate = readerWriter {
    if (runningBuildStep != null) {
      if (runningBuild == null) {
        throw ArgumentError(
          '`runningBuildStep` was set without `runningBuild`, they must`'
          'be both null or both set.',
        );
      }
      if (fakeRunningBuildStep != null) {
        throw ArgumentError(
          'Exactly one of `runningBuildStep` and '
          '`fakeRunningBuildStep` must be set, but both were set.',
        );
      }
    }
    if (runningBuildStep == null) {
      if (runningBuild != null) {
        throw ArgumentError(
          '`runningBuildStep` was not set but `runningBuild` '
          'was, they must be both null or both set.',
        );
      }
      if (fakeRunningBuildStep == null) {
        throw ArgumentError(
          'Exactly one of `runningBuildStep` and '
          '`fakeRunningBuildStep` must be set, but neither was set.',
        );
      }
    }
  }

  @override
  SingleStepReaderWriter copyWith({
    FilesystemCache? cache,
    FilesystemDigests? digests,
    GeneratedAssetHider? generatedAssetHider,
  }) => SingleStepReaderWriter(
    runningBuild: _runningBuild,
    runningBuildStep: _runningBuildStep,
    fakeRunningBuildStep: _fakeRunningBuildStep,
    readerWriter: _delegate.copyWith(
      cache: cache,
      digests: digests,
      generatedAssetHider: generatedAssetHider,
    ),
    inputTracker: inputTracker,
    assetsWritten: assetsWritten,
  );

  /// Constructs a `SingleStepReaderWriter` from [reader] and [writer].
  ///
  /// If [reader] and [writer] are the same `SingleStepReaderWriter`, returns
  /// it directly without creating a new instance. This is helpful when a real
  /// `SingleStepReaderWriter` is passed as `AssetReader` and `AssetWriter`
  /// through public-facing APIs.
  ///
  /// Otherwise, this constructor is for a cut down use case where the generator
  /// runs outside of a build, which is mostly for testing.
  ///
  /// Optionally pass [fakeStartingAssets] to cause the build step to only
  /// see starting assets and assets the step itself wrote. This approximates
  /// the behaviour during a build where a step can't see outputs from other
  /// generators running in the same or later phases.
  factory SingleStepReaderWriter.from({
    required AssetReader reader,
    required AssetWriter writer,
    Set<AssetId>? fakeStartingAssets,
  }) {
    AssetReaderWriter readerWriter;
    if (identical(reader, writer) && reader is AssetReaderWriter) {
      readerWriter = reader;
    } else {
      readerWriter = DelegatingAssetReaderWriter(
        reader: reader,
        writer: writer,
      );
    }

    if (readerWriter is SingleStepReaderWriter) {
      return readerWriter;
    } else {
      return SingleStepReaderWriter.fakeFor(
        readerWriter,
        fakeStartingAssets: fakeStartingAssets,
      );
    }
  }

  factory SingleStepReaderWriter.fakeFor(
    AssetReaderWriter assetReaderWriter, {
    Set<AssetId>? fakeStartingAssets,
  }) {
    return SingleStepReaderWriter(
      runningBuild: null,
      runningBuildStep: null,
      fakeRunningBuildStep: FakeRunningBuildStep(
        startingAssets: fakeStartingAssets,
      ),
      readerWriter: assetReaderWriter,
      inputTracker: InputTracker(assetReaderWriter.filesystem),
      assetsWritten: {},
    );
  }

  @override
  AssetPathProvider get assetPathProvider => _delegate.assetPathProvider;

  @override
  GeneratedAssetHider get generatedAssetHider => _delegate.generatedAssetHider;

  @override
  Filesystem get filesystem => _delegate.filesystem;

  @override
  FilesystemCache get cache => _delegate.cache;

  @override
  FilesystemDigests get digests => _delegate.digests;

  /// Checks whether [id] can be read by this step - attempting to build the
  /// asset if necessary.
  ///
  /// If [catchInvalidInputs] is set to true and [_checkInvalidInput] throws an
  /// [InvalidInputException], this method will return `false` instead of
  /// throwing.
  Future<bool> _isReadable(
    AssetId id, {
    bool catchInvalidInputs = false,
  }) async {
    try {
      _checkInvalidInput(id);
    } on InvalidInputException {
      if (catchInvalidInputs) return false;
      rethrow;
    } on PackageNotFoundException {
      if (catchInvalidInputs) return false;
      rethrow;
    }

    if (_runningBuild == null) {
      // For a fake build, files are readable if they were on the filesystem
      // when the step was created or they were written by the build step. This
      // approximates the real behaviour whereby a build step can see output
      // from earlier phases plus its own output.
      if (_fakeRunningBuildStep!.startingAssets != null) {
        if (!_fakeRunningBuildStep.startingAssets!.contains(id) &&
            !assetsWritten.contains(id)) {
          return false;
        }
      }
      inputTracker.add(id);
      return _delegate.canRead(id);
    }

    final node = _runningBuild.assetGraph.get(id);
    if (node == null) {
      inputTracker.add(id);
      _runningBuild.assetGraph.add(AssetNode.missingSource(id));
      return false;
    }

    final readability = await _isReadableNode(node);

    // If it's in the same phase it's never an input: it is either an output of
    // the current generator, which means it's readable but not an input, or
    // it's an output of a generator running in parallel, which means it's
    // hidden and can't be an input.
    if (!readability.inSamePhase) {
      inputTracker.add(id);
    }

    return readability.canRead;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    final isReadable = await _isReadable(id, catchInvalidInputs: true);
    if (!isReadable) return false;
    if (_runningBuild == null) return true;

    // No need to check readability for [GeneratedAssetNode], they are always
    // readable.

    if (_runningBuild.assetGraph.get(id)!.type == NodeType.generated &&
        !await _delegate.canRead(id)) {
      return false;
    }

    // If digests can be cached, cache it.
    // TODO(davidmorgan): remove?
    await _ensureDigest(id);
    return true;
  }

  @override
  Future<Digest> digest(AssetId id) async {
    final isReadable = await _isReadable(id);

    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    return _ensureDigest(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    final isReadable = await _isReadable(id);
    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    await _ensureDigest(id);
    return _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    final isReadable = await _isReadable(id);
    if (!isReadable) {
      throw AssetNotFoundException(id);
    }
    await _ensureDigest(id);
    return _delegate.readAsString(id, encoding: encoding);
  }

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  Stream<AssetId> _findAssets(Glob glob, String? package) {
    if (_runningBuild == null) {
      return _delegate.assetFinder.find(glob, package: package);
    }

    var streamCompleter = StreamCompleter<AssetId>();

    _buildGlobNode(glob.pattern).then((globNodeId) {
      inputTracker.add(globNodeId);
      final globNode = _runningBuild.assetGraph.get(globNodeId)!;
      streamCompleter.setSourceStream(
        Stream.fromIterable(globNode.globNodeState!.results),
      );
    });
    return streamCompleter.stream;
  }

  /// Returns the `lastKnownDigest` of [id], computing and caching it if
  /// necessary.
  ///
  /// Note that [id] must exist in the asset graph.
  FutureOr<Digest> _ensureDigest(AssetId id) {
    if (_runningBuild == null) return _delegate.digest(id);
    var node = _runningBuild.assetGraph.get(id)!;
    if (node.lastKnownDigest != null) return node.lastKnownDigest!;
    return _delegate.digest(id).then((digest) {
      _runningBuild.assetGraph.updateNode(id, (nodeBuilder) {
        nodeBuilder.lastKnownDigest = digest;
      });
      return digest;
    });
  }

  /// Checks whether [node] can be read by this step.
  ///
  /// If it's a generated node from an earlier phase, wait for it to be built.
  Future<Readability> _isReadableNode(AssetNode node) async {
    if (node.type == NodeType.generated) {
      final nodeConfiguration = node.generatedNodeConfiguration!;
      if (nodeConfiguration.phaseNumber > _runningBuildStep!.phaseNumber) {
        return Readability.notReadable;
      } else if (nodeConfiguration.phaseNumber ==
          _runningBuildStep.phaseNumber) {
        // allow a build step to read its outputs (contained in writtenAssets)
        final isInBuild =
            _runningBuildStep.buildPhase is InBuildPhase &&
            assetsWritten.contains(node.id);

        return isInBuild ? Readability.ownOutput : Readability.notReadable;
      }

      await _runningBuild!.nodeBuilder(node.id);
      node = _runningBuild.assetGraph.get(node.id)!;
      final nodeState = node.generatedNodeState!;
      return Readability.fromPreviousPhase(
        nodeState.wasOutput && !nodeState.isFailure,
      );
    }
    return Readability.fromPreviousPhase(node.isFile && node.isTrackedInput);
  }

  void _checkInvalidInput(AssetId id) {
    if (_runningBuild == null) return;

    final packageNode = _runningBuild.packageGraph[id.package];
    if (packageNode == null) {
      throw PackageNotFoundException(id.package);
    }

    // The id is an invalid input if it's not part of the build.
    if (!_runningBuild.targetGraph.isVisibleInBuild(id, packageNode)) {
      final allowed = _runningBuild.targetGraph.validInputsFor(packageNode);

      throw InvalidInputException(id, allowedGlobs: allowed);
    }
  }

  /// Builds an [AssetNode.glob] for [glob].
  ///
  /// Retrieves an existing node from `_runningBuild.assetGraph` if it's
  /// available; if not, adds one. Then, gets the built glob from
  /// `runningBuild.globNodeBuilder`, which might return an existing result.
  Future<AssetId> _buildGlobNode(String glob) async {
    var globNodeId = AssetNode.createGlobNodeId(
      _runningBuildStep!.primaryPackage,
      glob,
      _runningBuildStep.phaseNumber,
    );
    var globNode = _runningBuild!.assetGraph.get(globNodeId);
    if (globNode == null) {
      globNode = AssetNode.glob(
        globNodeId,
        glob: glob,
        phaseNumber: _runningBuildStep.phaseNumber,
        pendingBuildAction: PendingBuildAction.build,
      );
      _runningBuild.assetGraph.add(globNode);
    }
    await _runningBuild.globNodeBuilder(globNodeId);
    return globNodeId;
  }

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) {
    assetsWritten.add(id);
    return _delegate.writeAsBytes(id, bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) {
    assetsWritten.add(id);
    return _delegate.writeAsString(id, contents, encoding: encoding);
  }
}
