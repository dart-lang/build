// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'post_process_build_step.dart';
import 'post_process_builder.dart';

/// A [PostProcessBuilder] which can be configured to consume any input
/// extensions and always deletes it primary input.
class FileDeletingBuilder implements PostProcessBuilder {
  @override
  final List<String> inputExtensions;

  const FileDeletingBuilder(this.inputExtensions);

  @override
  FutureOr<Null> build(PostProcessBuildStep buildStep) {
    buildStep.deletePrimaryInput();
    return null;
  }
}
