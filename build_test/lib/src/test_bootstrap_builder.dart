// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:test/pub_serve.dart';

/// A [Builder] that bootstraps dart tests.
class TestBootstrapBuilder extends TransformerBuilder {
  TestBootstrapBuilder()
      : super(new PubServeTransformer.asPlugin(), {
          '_test.dart': [
            '_test.dart.vm_test.dart',
            '_test.dart.browser_test.dart',
            '_test.dart.node_test.dart',
          ]
        });

  @override
  Future<Null> build(BuildStep buildStep) async {
    if (!buildStep.inputId.path.endsWith('_test.dart')) return;
    await super.build(new _WrappedBuildStep(buildStep));
  }
}

/// Wraps a [BuildStep] and skips all writes for html files.
///
/// TODO: Remove this after https://github.com/dart-lang/build/issues/508
class _WrappedBuildStep implements BuildStep {
  final BuildStep _delegate;

  _WrappedBuildStep(this._delegate);

  @override
  get inputId => _delegate.inputId;

  @override
  get inputLibrary => _delegate.inputLibrary;

  @override
  fetchResource<T>(_) =>
      throw new UnimplementedError('fetchResource not implemented');

  /// Forwards everything except html file writes.
  @override
  Future writeAsBytes(AssetId id, FutureOr<List<int>> bytes) {
    if (id.path.endsWith('html')) return new Future.value(null);
    return _delegate.writeAsBytes(id, bytes);
  }

  /// Forwards everything except html file writes.
  @override
  Future writeAsString(AssetId id, FutureOr<String> contents,
      {Encoding encoding: utf8}) {
    if (id.path.endsWith('html')) return new Future.value(null);
    return _delegate.writeAsString(id, contents, encoding: encoding);
  }

  @override
  get resolver => _delegate.resolver;

  @override
  readAsBytes(_) => _delegate.readAsBytes(_);

  @override
  readAsString(_, {Encoding encoding: utf8}) =>
      _delegate.readAsString(_, encoding: encoding);

  @override
  canRead(_) => _delegate.canRead(_);

  @override
  findAssets(_) => _delegate.findAssets(_);

  @override
  digest(_) => _delegate.digest(_);
}
