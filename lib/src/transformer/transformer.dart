// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart' as barback show Asset, AssetId;
import 'package:barback/barback.dart' hide Asset, AssetId;

import '../asset/asset.dart' as build;
import '../asset/id.dart' as build;
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../builder/builder.dart';
import '../builder/build_step.dart';

abstract class BuilderTransformer implements Transformer, DeclaringTransformer {
  List<Builder> get builders;

  @override
  String get allowedExtensions => null;

  @override
  bool isPrimary(barback.AssetId id) =>
      _expectedOutputs(id, builders).isNotEmpty;

  @override
  Future apply(Transform transform) async {
    var input = await _toBuildAsset(transform.primaryInput);
    var reader = new _TransformAssetReader(transform);
    var writer = new _TransformAssetWriter(transform);

    var futures = <Future>[];
    for (var builder in builders) {
      var expected = _expectedOutputs(transform.primaryInput.id, [builder]);
      if (expected.isEmpty) continue;

      var buildStep = new BuildStep(input, expected, reader, writer);
      futures.add(builder.build(buildStep));
    }

    await Future.wait(futures);
  }

  @override
  void declareOutputs(DeclaringTransform transform) {
    for (var outputId in _expectedOutputs(transform.primaryId, builders)) {
      transform.declareOutput(_toBarbackAssetId(outputId));
    }
  }
}

/// Very simple [AssetReader] which uses a [Transform].
class _TransformAssetReader implements AssetReader {
  final Transform transform;

  _TransformAssetReader(this.transform);

  @override
  Future<String> readAsString(build.AssetId id, {Encoding encoding: UTF8}) =>
      transform.readInputAsString(_toBarbackAssetId(id), encoding: encoding);
}

/// Very simple [AssetWriter] which uses a [Transform].
class _TransformAssetWriter implements AssetWriter {
  final Transform transform;

  _TransformAssetWriter(this.transform);

  @override
  Future writeAsString(build.Asset asset, {Encoding encoding: UTF8}) async =>
      transform.addOutput(_toBarbackAsset(asset));
}

/// All the expected outputs for [id] given [builders].
Iterable<build.AssetId> _expectedOutputs(
    barback.AssetId id, Iterable<Builder> builders) sync* {
  for (var builder in builders) {
    yield* builder.declareOutputs(_toBuildAssetId(id));
  }
}

barback.AssetId _toBarbackAssetId(build.AssetId id) =>
    new barback.AssetId(id.package, id.path);

build.AssetId _toBuildAssetId(barback.AssetId id) =>
    new build.AssetId(id.package, id.path);

barback.Asset _toBarbackAsset(build.Asset asset) =>
    new barback.Asset.fromString(
        _toBarbackAssetId(asset.id), asset.stringContents);

Future<build.Asset> _toBuildAsset(barback.Asset asset) async =>
    new build.Asset(_toBuildAssetId(asset.id), await asset.readAsString());
