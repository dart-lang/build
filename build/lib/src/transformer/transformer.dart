// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart' as barback show AssetId;
import 'package:barback/barback.dart' hide Asset, AssetId;
import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../asset/asset.dart' as build;
import '../asset/id.dart' as build;
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/build_step_impl.dart';
import '../builder/builder.dart';
import '../util/barback.dart';

/// A [Transformer] which runs a single [Builder] with a new [BuildStep].
///
/// By default all [BuilderTransformer]s are [DeclaringTransformer]s. If you
/// wish to run as a [LazyTransformer], extend this class and mix in
/// LazyTransformer.
class BuilderTransformer implements Transformer, DeclaringTransformer {
  final Builder _builder;
  final Resolvers _resolvers;

  BuilderTransformer(this._builder, {Resolvers resolvers: const Resolvers()})
      : this._resolvers = resolvers;

  @override
  String get allowedExtensions => null;

  @override
  bool isPrimary(barback.AssetId id) =>
      _builder.declareOutputs(toBuildAssetId(id)).isNotEmpty;

  @override
  Future apply(Transform transform) async {
    var input = await toBuildAsset(transform.primaryInput);
    var reader = new _TransformAssetReader(transform);
    var writer = new _TransformAssetWriter(transform);

    var expected =
        _builder.declareOutputs(toBuildAssetId(transform.primaryInput.id));
    if (expected.isEmpty) return;

    // Check for overlapping outputs.
    var uniqueExpected = new Set<build.AssetId>();
    var preExistingFiles = [];
    for (var output in expected) {
      if (!uniqueExpected.add(output) ||
          await transform.hasInput(toBarbackAssetId(output))) {
        preExistingFiles.add(toBarbackAssetId(output));
      }
    }
    if (preExistingFiles.isNotEmpty) {
      transform.logger.error(
          'Builder `$_builder` declared outputs `$preExistingFiles` but those '
          'files already exist. This build step has been skipped.',
          asset: transform.primaryInput.id);
      return;
    }

    // Run the build step.
    var buildStep = new BuildStepImpl(
        input, expected, reader, writer, input.id.package, _resolvers);
    Logger.root.level = Level.ALL;
    var logSubscription = buildStep.logger.onRecord.listen((LogRecord log) {
      if (log.loggerName != buildStep.logger.fullName) return;

      if (log.level <= Level.CONFIG) {
        transform.logger.fine(_logRecordToMessage(log));
      } else if (log.level <= Level.INFO) {
        transform.logger.info(_logRecordToMessage(log));
      } else if (log.level <= Level.WARNING) {
        transform.logger.warning(_logRecordToMessage(log));
      } else {
        transform.logger.error(_logRecordToMessage(log));
      }
    });
    await _builder.build(buildStep);
    await buildStep.complete();
    await logSubscription.cancel();
  }

  String _logRecordToMessage(LogRecord log) {
    var buffer = new StringBuffer();
    buffer.write(log.message);
    if (log.error != null) {
      buffer.write('\nError: ${log.error}');
    }
    if (log.stackTrace != null) {
      buffer.write('\nStack Trace:\n${log.stackTrace}');
    }
    return buffer.toString();
  }

  @override
  void declareOutputs(DeclaringTransform transform) {
    var outputs = _builder.declareOutputs(toBuildAssetId(transform.primaryId));
    outputs.map(toBarbackAssetId).forEach(transform.declareOutput);
  }

  @override
  String toString() => 'BuilderTransformer: $_builder';
}

/// Very simple [AssetReader] which uses a [Transform].
class _TransformAssetReader implements AssetReader {
  final Transform transform;

  _TransformAssetReader(this.transform);

  @override
  Future<bool> hasInput(build.AssetId id) =>
      transform.hasInput(toBarbackAssetId(id));

  @override
  Future<String> readAsString(build.AssetId id, {Encoding encoding: UTF8}) =>
      transform.readInputAsString(toBarbackAssetId(id), encoding: encoding);

  /// No way to implement this, but luckily its not necessary.
  @override
  Stream<build.AssetId> listAssetIds(_) => throw new UnimplementedError();

  /// No way to implement this, but luckily its not necessary.
  @override
  Future<DateTime> lastModified(_) => throw new UnimplementedError();
}

/// Very simple [AssetWriter] which uses a [Transform].
class _TransformAssetWriter implements AssetWriter {
  final Transform transform;

  _TransformAssetWriter(this.transform);

  @override
  Future writeAsString(build.Asset asset, {Encoding encoding: UTF8}) {
    transform.addOutput(toBarbackAsset(asset));
    return new Future.value(null);
  }

  @override
  Future delete(build.AssetId id) =>
      throw new UnsupportedError('_TransformAssetWriter can\'t delete files.');
}
