// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:barback/barback.dart' as barback;

import '../asset/id.dart';
import '../builder/builder.dart';
import '../util/barback.dart';
import 'build_step.dart';

/// A builder which wraps a [barback.DeclaringTransformer].
class TransformerBuilder implements Builder {
  final barback.Transformer transformer;

  TransformerBuilder(this.transformer) {
    /// Unfortunately, we can't add a static type for this :(.
    if (transformer is! barback.DeclaringTransformer) {
      throw new ArgumentError('Only DeclaringTransformers are supported, which '
          '$transformer is not');
    }
  }

  @override
  Future build(BuildStep buildStep) {
    var transform = toBarbackTransform(buildStep);
    return transformer.apply(transform);
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) {
    var barbackId = toBarbackAssetId(inputId);
    if (!transformer.isPrimary(barbackId)) return const [];
    var transform = new _DeclaringTransform(barbackId);
    (transformer as barback.DeclaringTransformer).declareOutputs(transform);
    return transform.outputs;
  }
}

/// A [barback.DeclaringTransform] which just collects outputs.
class _DeclaringTransform implements barback.DeclaringTransform {
  final List<AssetId> outputs = [];

  @override
  final barback.AssetId primaryId;

  _DeclaringTransform(this.primaryId);

  @override
  barback.TransformLogger get logger => throw new UnimplementedError();

  @override
  void declareOutput(barback.AssetId id) {
    outputs.add(toBuildAssetId(id));
  }

  @override
  void consumePrimary() => throw new UnsupportedError(
      'Consuming inputs is not allowed for builders.');
}
