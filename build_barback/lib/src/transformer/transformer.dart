// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart' as build;
import 'package:build/build.dart' hide AssetId;
import 'package:barback/barback.dart' as barback show AssetId;
import 'package:barback/barback.dart' hide Asset, AssetId;
import 'package:logging/logging.dart';

import '../analyzer/resolver.dart';
import '../util/barback.dart';
import '../util/stream.dart';

/// A [Transformer] which runs a single [Builder] with a new [BuildStep].
///
/// By default all [BuilderTransformer]s are [DeclaringTransformer]s. If you
/// wish to run as a [LazyTransformer], extend this class and mix in
/// LazyTransformer.
class BuilderTransformer implements Transformer, DeclaringTransformer {
  final Builder _builder;
  final Resolvers _resolvers;

  BuilderTransformer(this._builder,
      {Resolvers resolvers: const BarbackResolvers()})
      : this._resolvers = resolvers;

  @override
  String get allowedExtensions => null;

  @override
  bool isPrimary(barback.AssetId id) =>
      _builder.declareOutputs(toBuildAssetId(id)).isNotEmpty;

  @override
  Future apply(Transform transform) async {
    var inputId = toBuildAssetId(transform.primaryInput.id);
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

    hierarchicalLoggingEnabled = true;

    var logger = new Logger.detached('BuilderTransformer-$inputId');
    logger.level = Level.ALL;
    var logSubscription = logger.onRecord.listen((LogRecord log) {
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

    // Run the build step.
    var buildStep = new ManagedBuildStep(
        inputId, expected, reader, writer, inputId.package, _resolvers,
        logger: logger);
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
  Future<List<int>> readAsBytes(build.AssetId id) async =>
      await combineByteStream(transform.readInput(toBarbackAssetId(id)));

  @override
  Future<String> readAsString(build.AssetId id, {Encoding encoding: UTF8}) =>
      transform.readInputAsString(toBarbackAssetId(id), encoding: encoding);
}

/// Very simple [AssetWriter] which uses a [Transform].
class _TransformAssetWriter implements AssetWriter {
  final Transform transform;

  _TransformAssetWriter(this.transform);

  @override
  Future writeAsBytes(build.AssetId id, List<int> bytes) {
    transform.addOutput(barbackAssetFromBytes(id, bytes));
    return new Future.value(null);
  }

  @override
  Future writeAsString(build.AssetId id, String contents,
      {Encoding encoding: UTF8}) {
    transform.addOutput(barbackAssetFromString(id, contents));
    return new Future.value(null);
  }
}
