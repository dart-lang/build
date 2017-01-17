// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart' as barback;
import 'package:build/build.dart' as build;
import 'package:build/src/builder/build_step_impl.dart';
import 'package:logging/logging.dart';

import 'stream.dart';

barback.AssetId toBarbackAssetId(build.AssetId id) =>
    new barback.AssetId(id.package, id.path);

build.AssetId toBuildAssetId(barback.AssetId id) =>
    new build.AssetId(id.package, id.path);

barback.Asset barbackAssetFromBytes(build.AssetId id, List<int> bytes) =>
    new barback.Asset.fromBytes(toBarbackAssetId(id), bytes);

barback.Asset barbackAssetFromString(build.AssetId id, String contents) =>
    new barback.Asset.fromString(toBarbackAssetId(id), contents);

barback.Transform toBarbackTransform(build.BuildStep buildStep) =>
    new BuildStepTransform(buildStep);

class BuildStepTransform implements barback.Transform {
  final build.BuildStep buildStep;

  BuildStepTransform(this.buildStep);

  @override
  barback.Asset get primaryInput {
    var id = toBarbackAssetId(buildStep.inputId);
    return new _BuildStepAsset(id, buildStep);
  }

  @override
  barback.TransformLogger get logger {
    _logger ??= toTransformLogger(buildStep.logger);
    return _logger;
  }

  barback.TransformLogger _logger;

  @override
  Future<barback.Asset> getInput(barback.AssetId id,
          {Encoding encoding: UTF8}) async =>
      new barback.Asset.fromString(
          id, await readInputAsString(id, encoding: encoding));

  @override
  Future<String> readInputAsString(barback.AssetId id,
          {Encoding encoding: UTF8}) =>
      buildStep.readAsString(toBuildAssetId(id), encoding: encoding);

  @override
  Stream<List<int>> readInput(barback.AssetId id) async* {
    yield await buildStep.readAsBytes(toBuildAssetId(id));
  }

  @override
  Future<bool> hasInput(barback.AssetId id) =>
      buildStep.hasInput(toBuildAssetId(id));

  @override
  void addOutput(barback.Asset output) {
    (buildStep as BuildStepImpl).writeFromFutureAsBytes(
        toBuildAssetId(output.id), combineByteStream(output.read()));
  }

  @override
  void consumePrimary() => throw new UnimplementedError();
}

const _barbackLevelToLoggingLevel = const {
  barback.LogLevel.FINE: Level.FINE,
  barback.LogLevel.INFO: Level.INFO,
  barback.LogLevel.WARNING: Level.WARNING,
  barback.LogLevel.ERROR: Level.SEVERE,
};

barback.TransformLogger toTransformLogger(Logger logger) {
  return new barback.TransformLogger((asset, level, message, span) {
    var buffer = new StringBuffer();
    if (asset != null) {
      buffer.write('From $asset');
      if (span != null) {
        buffer.write('()$span)');
      }
      buffer.write(': ');
    }
    buffer.write(message);
    var logLevel = _barbackLevelToLoggingLevel[level];
    if (logLevel == null) throw 'Unrecognized LogLevel $level.';
    logger.log(logLevel, buffer);
  });
}

class _BuildStepAsset implements barback.Asset {
  final barback.AssetId id;
  final build.BuildStep _buildStep;

  _BuildStepAsset(this.id, this._buildStep);

  Stream<List<int>> read() async* {
    yield await _buildStep.readAsBytes(toBuildAssetId(id));
  }

  Future<String> readAsString({Encoding encoding: UTF8}) =>
      _buildStep.readAsString(toBuildAssetId(id), encoding: encoding);
}
