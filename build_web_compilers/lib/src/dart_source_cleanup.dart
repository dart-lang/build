// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

class DartSourceCleanup implements PostProcessBuilder {
  final bool isEnabled;

  const DartSourceCleanup(this.isEnabled);

  DartSourceCleanup.fromOptions(BuilderOptions options)
      : isEnabled = options.config['enabled'] as bool ?? false;

  @override
  FutureOr<Null> build(PostProcessBuildStep buildStep) {
    if (!isEnabled) return null;
    buildStep.deletePrimaryInput();
    return null;
  }

  @override
  final inputExtensions = const ['.dart'];
}
