// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:test/pub_serve.dart';

/// A [Builder] that bootstraps
class TestBootstrapBuilder extends TransformerBuilder {
  TestBootstrapBuilder()
      : super(new PubServeTransformer.asPlugin(), {
          '.dart': [
            '.dart.vm_test.dart',
            '.dart.browser_test.dart',
            '.dart.node_test.dart',
            '.html',
          ]
        });

  @override
  Future<Null> build(BuildStep buildStep) async {
    if (!buildStep.inputId.path.endsWith('_test.dart')) return;
    await super.build(buildStep);
  }
}
