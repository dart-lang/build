// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

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

class DeletePostProcessBuilder implements PostProcessBuilder {
  @override
  final inputExtensions = ['.txt'];

  DeletePostProcessBuilder();

  @override
  Future<Null> build(PostProcessBuildStep buildStep) async {
    buildStep.deletePrimaryInput();
  }
}
