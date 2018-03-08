// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';

class _SomeBuilder implements Builder {
  const _SomeBuilder();

  factory _SomeBuilder.fromOptions(BuilderOptions options) {
    if (options.config['throw_in_constructor'] == true) {
      throw new StateError('Throwing on purpose cause you asked for it!');
    }
    return const _SomeBuilder();
  }

  @override
  final buildExtensions = const {
    '.dart': const ['.something.dart']
  };

  @override
  Future build(BuildStep buildStep) async {
    if (!await buildStep.canRead(buildStep.inputId)) return;

    await buildStep.writeAsBytes(
        buildStep.inputId.changeExtension('.something.dart'),
        buildStep.readAsBytes(buildStep.inputId));
  }
}

class _SomePostProcessBuilder extends PostProcessBuilder {
  @override
  final inputExtensions = const ['.txt'];

  final String defaultContent;

  _SomePostProcessBuilder.fromOptions(BuilderOptions options)
      : defaultContent = options.config['default_content'] as String;

  @override
  Future<Null> build(BuildStep buildStep) async {
    var content =
        defaultContent ?? await buildStep.readAsString(buildStep.inputId);
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.txt.post'), content);
  }
}

Builder someBuilder(BuilderOptions options) =>
    new _SomeBuilder.fromOptions(options);
Builder notApplied(_) => null;
PostProcessBuilder somePostProcessBuilder(BuilderOptions options) =>
    new _SomePostProcessBuilder.fromOptions(options);
