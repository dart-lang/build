// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/src/builder/post_process_builder.dart';
import 'package:build_runner/src/builder/post_process_build_step.dart';

class CopyingPostProcessBuilder implements PostProcessBuilder {
  final String outputExtension;

  @override
  final inputExtensions = ['.txt'];

  CopyingPostProcessBuilder({this.outputExtension = '.copy'});

  @override
  Future<Null> build(PostProcessBuildStep buildStep) async {
    await buildStep.writeAsString(
        buildStep.inputId.addExtension(outputExtension),
        await buildStep.readInputAsString());
  }
}
