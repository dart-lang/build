// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner_core/src/util/constants.dart';
import 'package:build_test/build_test.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// Test case which build steps are triggered by changes to files.
///
/// For concise tests, "names" are used instead of asset IDs. The name `a` maps
/// to the path `lib/a.dart`; all names map to the package `pkg`. "Hidden" asset
/// IDs under `.dart_tool` are mapped back to the same namespace.
class InvalidationTester {
  /// The source assets on disk before the first build.
  final Set<AssetId> _sourceAssets = {};

  /// Import statements.
  ///
  /// If an asset has an entry here then sources and generated sources will
  /// start with the import statements specified.
  final Map<String, List<String>> _importGraph = {};

  /// The builders that will run.
  final List<TestBuilder> _builders = [];

  /// The [OutputStrategy] for generated assets.
  ///
  /// [OutputStrategy.inputDigest] is the default if there is no entry.
  final Map<AssetId, OutputStrategy> _outputStrategies = {};

  /// The [FailureStrategy] for generated assets.
  ///
  /// [FailureStrategy.succeed] is the default if there is no entry.
  final Map<AssetId, FailureStrategy> _failureStrategies = {};

  /// Assets written by generators.
  final Set<AssetId> _generatedOutputsWritten = {};

  /// The [TestReaderWriter] from the most recent build.
  TestReaderWriter? _readerWriter;

  /// The build number for "printOnFailure" output.
  int _buildNumber = 0;

  /// Output number, for writing outputs that are different.
  int _outputNumber = 0;

  /// Sets the assets that will be on disk before the first build.
  ///
  /// See the note on "names" in the class dartdoc.
  void sources(Iterable<String> names) {
    _sourceAssets.clear();
    for (final name in names) {
      _sourceAssets.add(name.assetId);
    }
  }

  // Sets the import graph for source files and generated files.
  void importGraph(Map<String, List<String>> importGraph) {
    _importGraph.clear();
    _importGraph.addAll(importGraph);
  }

  /// Adds a builder to the test.
  ///
  /// [from] and [to] are the input and output extension of the builder,
  /// without ".dart". So `from: '', to: '.g'` is a builder that takes `.dart`
  /// files as primary inputs and outputs corresponding `.g.dart` files.
  ///
  /// Set [isOptional] to make the builder optional. Optional builders only run
  /// if their output is depended on by a non-optional builder.
  ///
  /// Returns a [TestBuilderBuilder], use it to specify what the builder does.
  TestBuilderBuilder builder({
    required String from,
    required String to,
    bool isOptional = false,
  }) {
    final builder = TestBuilder(this, from, [to], isOptional);
    _builders.add(builder);
    return TestBuilderBuilder(builder);
  }

  /// Sets the output strategy for [name] to [OutputStrategy.fixed].
  ///
  /// By default, output will be a digest of all read files. This changes it to
  /// fixed: it won't change when inputs change.
  void fixOutput(String name) {
    _outputStrategies[name.assetId] = OutputStrategy.fixed;
  }

  /// Sets the output strategy for [name] back to the default,
  /// [OutputStrategy.inputDigest].
  void digestOutput(String name) {
    _outputStrategies[name.assetId] = OutputStrategy.inputDigest;
  }

  /// Sets the output strategy for [name] to [OutputStrategy.none].
  ///
  /// The generator will not output the file.
  void skipOutput(String name) {
    _outputStrategies[name.assetId] = OutputStrategy.none;
  }

  /// Sets the failure strategy for [name] to [FailureStrategy.fail].
  ///
  /// The generator will write any outputs it is configured to write, then fail.
  void fail(String name) {
    _failureStrategies[name.assetId] = FailureStrategy.fail;
  }

  /// Sets the failure strategy for [name] to [FailureStrategy.succeed].
  void succeed(String name) {
    _failureStrategies[name.assetId] = FailureStrategy.succeed;
  }

  String _imports(AssetId id) {
    final imports = _importGraph[_assetIdToName(id)];
    return imports == null
        ? ''
        : imports.map((i) => "import '${i.pathForImport}';").join('\n');
  }

  /// Does a build.
  ///
  /// For the initial build, do not pass [change] [delete] or [create].
  ///
  /// For subsequent builds, pass asset name [change] to change that asset;
  /// [delete] to delete one; and/or [create] to create one.
  Future<Result> build({String? change, String? delete, String? create}) async {
    final assets = <AssetId, String>{};
    if (_readerWriter == null) {
      // Initial build.
      if (change != null || delete != null || create != null) {
        throw StateError('Do a build without change, delete or create first.');
      }
      for (final id in _sourceAssets) {
        assets[id] = '${_imports(id)}// initial source';
      }
    } else {
      // Create the new filesystem from the previous build state.
      for (final id in _readerWriter!.testing.assets) {
        assets[id] = _readerWriter!.testing.readString(id);
      }
    }

    // Make the requested updates.
    if (change != null) {
      assets[change.assetId] =
          '${_imports(change.assetId)}\n// ${++_outputNumber}';
    }
    if (delete != null) {
      if (assets.containsKey(delete.assetId)) {
        assets.remove(delete.assetId);
      } else {
        if (assets.containsKey(delete.generatedAssetId)) {
          assets.remove(delete.generatedAssetId);
        } else {
          throw StateError('Did not find $delete to delete in: $assets');
        }
      }
    }
    if (create != null) {
      if (assets.containsKey(create.assetId)) {
        throw StateError('Asset $create to create already exists in: $assets');
      }
      assets[create.assetId] = '${_imports(create.assetId)}// initial source';
    }

    // Build and check what changed.
    final startingAssets = assets.keys.toSet();
    _generatedOutputsWritten.clear();
    final log = StringBuffer();
    final testBuildResult = await testBuilders(
      onLog: (record) => log.writeln(record.display),
      _builders,
      assets.map((id, content) => MapEntry(id.toString(), content)),
      rootPackage: 'pkg',
      optionalBuilders: _builders.where((b) => b.isOptional).toSet(),
      testingBuilderConfig: false,
    );
    final logString = log.toString();
    printOnFailure(
      '=== build log #${++_buildNumber} ===\n\n'
      '${logString.trimAndIndent}',
    );
    _readerWriter = testBuildResult.readerWriter;

    final written = _generatedOutputsWritten.map(_assetIdToName);
    final deletedAssets = startingAssets.difference(
      _readerWriter!.testing.assets.toSet(),
    );
    final deleted = deletedAssets.map(_assetIdToName);

    return logString.contains('Succeeded after')
        ? Result(written: written, deleted: deleted)
        : Result.failure(written: written, deleted: deleted);
  }

  /// The size of the asset graph that was written by [build], in bytes.
  int get assetGraphSize =>
      _readerWriter!.testing.readBytes(AssetId('pkg', assetGraphPath)).length;
}

/// Strategy used by generators for outputting files.
enum OutputStrategy {
  /// Output nothing.
  none,

  /// Output with fixed content.
  fixed,

  /// Output with digest of all files that were read.
  inputDigest,
}

/// Whether a generator succeeds or fails.
///
/// Writing files is independent from success or failure: if a generator is
/// configured to write files, it does so before failing.
enum FailureStrategy { fail, succeed }

/// The changes on disk caused by the build.
class Result {
  /// The "names" of the assets that were written.
  BuiltSet<String> written;

  /// The "names" of the assets that were deleted.
  BuiltSet<String> deleted;

  /// Whether the build succeeded.
  bool succeeded;

  Result({Iterable<String>? written, Iterable<String>? deleted})
    : written = (written ?? {}).toBuiltSet(),
      deleted = (deleted ?? {}).toBuiltSet(),
      succeeded = true;

  Result.failure({Iterable<String>? written, Iterable<String>? deleted})
    : written = (written ?? {}).toBuiltSet(),
      deleted = (deleted ?? {}).toBuiltSet(),
      succeeded = false;

  @override
  bool operator ==(Object other) {
    if (other is! Result) return false;
    return succeeded == other.succeeded &&
        written == other.written &&
        deleted == other.deleted;
  }

  @override
  int get hashCode => Object.hash(succeeded, written, deleted);

  @override
  String toString() => [
    'Result(',
    if (!succeeded) 'failed',
    if (written.isNotEmpty) 'written: ${written.join(', ')}',
    if (deleted.isNotEmpty) 'deleted: ${deleted.join(', ')}',
    ')',
  ].join('\n');
}

/// Sets test setup on a [TestBuilder].
class TestBuilderBuilder {
  final TestBuilder _builder;

  TestBuilderBuilder(this._builder);

  /// Test setup: the builder will read the asset that is [extension] applied to
  /// the primary input.
  void reads(String extension) {
    _builder.reads.add('$extension.dart');
  }

  /// Test setup: the builder will read the asset with [name].
  void readsOther(String name) {
    _builder.otherReads.add(name);
  }

  /// Test setup: the builder will parse the Dart source asset with [name].
  void resolvesOther(String name) {
    _builder.otherResolves.add(name);
  }

  /// Test setup: the builder will write the asset that is [extension] applied
  /// to the primary input.
  ///
  /// The output will be new for this generation, unless the asset was
  /// fixed with `fixOutputs`.
  void writes(String extension) {
    _builder.writes.add('$extension.dart');
  }
}

/// A builder that does reads and writes according to test setup.
class TestBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  final bool isOptional;

  final InvalidationTester _tester;

  /// Extensions of assets that the builder will read.
  ///
  /// The extensions are applied to the primary input asset ID with
  /// [AssetIdExtension.replaceAllPathExtensions].
  List<String> reads = [];

  /// Names of assets that the builder will read.
  List<String> otherReads = [];

  /// Names of assets that the builder will resolve.
  List<String> otherResolves = [];

  /// Extensions of assets that the builder will write.
  ///
  /// The extensions are applied to the primary input asset ID with
  /// [AssetIdExtension.replaceAllPathExtensions].
  List<String> writes = [];

  TestBuilder(this._tester, String from, Iterable<String> to, this.isOptional)
    : buildExtensions = {'$from.dart': to.map((to) => '$to.dart').toList()};

  @override
  Future<void> build(BuildStep buildStep) async {
    final content = <String>[];
    for (final read in reads) {
      final readId = buildStep.inputId.replaceAllPathExtensions(read);
      content.add(read.toString());
      if (await buildStep.canRead(readId)) {
        content.add(await buildStep.readAsString(readId));
      }
    }
    for (final read in otherReads) {
      content.add(read.assetId.toString());
      if (await buildStep.canRead(read.assetId)) {
        content.add(await buildStep.readAsString(read.assetId));
      }
    }
    for (final resolve in otherResolves) {
      content.add(resolve.assetId.toString());
      await buildStep.resolver.libraryFor(resolve.assetId);
    }
    for (final write in writes) {
      final writeId = buildStep.inputId.replaceAllPathExtensions(write);
      final outputStrategy =
          _tester._outputStrategies[writeId] ?? OutputStrategy.inputDigest;
      final inputHash = base64.encode(
        md5.convert(utf8.encode(content.join('\n\n'))).bytes,
      );
      final output = switch (outputStrategy) {
        OutputStrategy.fixed => _tester._imports(writeId),
        OutputStrategy.inputDigest =>
          '${_tester._imports(writeId)}\n// $inputHash',
        OutputStrategy.none => null,
      };
      if (output != null) {
        await buildStep.writeAsString(writeId, output);
        _tester._generatedOutputsWritten.add(writeId);
      }
    }
    for (final write in writes) {
      final writeId = buildStep.inputId.replaceAllPathExtensions(write);
      if (_tester._failureStrategies[writeId] == FailureStrategy.fail) {
        throw StateError('Failing as requested by test setup.');
      }
    }
  }
}

extension LogRecordExtension on LogRecord {
  /// Displays [toString] plus error and stack trace if present.
  String get display {
    if (error == null && stackTrace == null) return message;
    return '${toString()}\n$error\n$stackTrace';
  }
}

extension StringExtension on String {
  /// Maps "names" to [AssetId]s.
  ///
  /// See [InvalidationTester] class dartdoc.
  AssetId get assetId => AssetId('pkg', 'lib/$this.dart');

  /// Maps "names" to [AssetId]s under `build/generated`.
  AssetId get generatedAssetId =>
      AssetId('pkg', '.dart_tool/build/generated/pkg/lib/$this.dart');

  /// Maps "names" to relative import path.
  String get pathForImport => '$this.dart';

  /// Displays trimmed and with two space indent.
  String get trimAndIndent => '  ${toString().trim().replaceAll('\n', '\n  ')}';
}

/// Converts [StringExtension.assetId] and [StringExtension.generatedAssetId]
/// back to [AssetId].
String _assetIdToName(AssetId id) {
  final path = id.path.replaceAll('.dart_tool/build/generated/pkg/', '');
  if (id.package != 'pkg' ||
      !path.startsWith('lib/') ||
      !path.endsWith('.dart')) {
    throw ArgumentError('Unexpected: $id');
  }
  return path.substring('lib/'.length, path.length - '.dart'.length);
}

extension AssetIdExtension on AssetId {
  static final extensionsRegexp = RegExp(r'\..*');

  AssetId replaceAllPathExtensions(String extension) =>
      AssetId(package, path.replaceAll(extensionsRegexp, '') + extension);
}
