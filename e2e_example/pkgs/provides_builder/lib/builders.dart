// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

class _SomeBuilder implements Builder {
  const _SomeBuilder();

  @override
  final buildExtensions = const {
    '': const ['.copy']
  };

  @override
  Future build(BuildStep buildStep) async {
    if (!await buildStep.canRead(buildStep.inputId)) return;

    await buildStep.writeAsBytes(buildStep.inputId.addExtension('.copy'),
        buildStep.readAsBytes(buildStep.inputId));
  }
}

Builder someBuilder(_) => const _SomeBuilder();
Builder notApplied(_) => null;
