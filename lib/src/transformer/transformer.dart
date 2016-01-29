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
import '../builder/build_step_impl.dart';

/// A [Transformer] which runs multiple [Builder]s.
/// Extend this class and define the [builders] getter to create a [Transformer]
/// out of your custom [Builder]s.
///
/// By default all [BuilderTransformer]s are [DeclaringTransformer]s. If you
/// wish to run as a [LazyTransformer], simply mix that into your class as well.
abstract class BuilderTransformer implements Transformer, DeclaringTransformer {
  /// The only thing you need to implement when extending this class. This
  /// declares which builders should be ran.
  ///
  /// **Note**: All [builders] are ran in the same phase, and there are no
  /// ordering guarantees. Thus, none of the [builders] can use the outputs of
  /// other [builders]. In order to do this you must create a [TransformerGroup]
  /// with multiple [BuilderTransformer]s.
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

    // Tracks all the expected outputs for each builder to make sure they don't
    // overlap.
    var allExpected = new Set<build.AssetId>();

    // Run all builders at the same time.
    await Future.wait(builders.map((builder) async {
      var expected = _expectedOutputs(transform.primaryInput.id, [builder]);
      if (expected.isEmpty) return;

      // Check that no expected outputs already exist.
      var preExistingFiles = [];
      for (var output in expected) {
        if (!allExpected.add(output) ||
            await transform.hasInput(_toBarbackAssetId(output))) {
          preExistingFiles.add(_toBarbackAssetId(output));
        }
      }
      if (preExistingFiles.isNotEmpty) {
        transform.logger.error(
            'Builder `$builder` declared outputs `$preExistingFiles` but those '
            'files already exist. That build step has been skipped.',
            asset: transform.primaryInput.id);
        return;
      }

      // Run the build step.
      var buildStep = new BuildStepImpl(input, expected, reader, writer);
      await builder.build(buildStep);
      await buildStep.outputsCompleted;
    }));
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
  Future<bool> hasInput(build.AssetId id) =>
      transform.hasInput(_toBarbackAssetId(id));

  @override
  Future<String> readAsString(build.AssetId id, {Encoding encoding: UTF8}) =>
      transform.readInputAsString(_toBarbackAssetId(id), encoding: encoding);
}

/// Very simple [AssetWriter] which uses a [Transform].
class _TransformAssetWriter implements AssetWriter {
  final Transform transform;

  _TransformAssetWriter(this.transform);

  @override
  Future writeAsString(build.Asset asset, {Encoding encoding: UTF8}) {
    transform.addOutput(_toBarbackAsset(asset));
    return new Future.value(null);
  }
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
