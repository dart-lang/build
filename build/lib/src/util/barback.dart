// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart' as barback;
import 'package:logging/logging.dart';

import '../asset/asset.dart' as build;
import '../asset/id.dart' as build;
import '../builder/build_step.dart' as build;

barback.AssetId toBarbackAssetId(build.AssetId id) =>
    new barback.AssetId(id.package, id.path);

build.AssetId toBuildAssetId(barback.AssetId id) =>
    new build.AssetId(id.package, id.path);

barback.Asset toBarbackAsset(build.Asset asset) => new barback.Asset.fromString(
    toBarbackAssetId(asset.id), asset.stringContents);

Future<build.Asset> toBuildAsset(barback.Asset asset) async =>
    new build.Asset(toBuildAssetId(asset.id), await asset.readAsString());

barback.Transform toBarbackTransform(build.BuildStep buildStep) =>
    new BuildStepTransform(buildStep);

class BuildStepTransform implements barback.Transform {
  final build.BuildStep buildStep;

  BuildStepTransform(this.buildStep);

  @override
  barback.Asset get primaryInput => toBarbackAsset(buildStep.input);

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
  Stream<List<int>> readInput(barback.AssetId id) =>
      throw new UnimplementedError();

  @override
  Future<bool> hasInput(barback.AssetId id) =>
      buildStep.hasInput(toBuildAssetId(id));

  @override
  void addOutput(barback.Asset output) {
    toBuildAsset(output).then((asset) {
      buildStep.writeAsString(asset);
    });
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
