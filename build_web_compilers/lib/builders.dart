// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'package:build_web_compilers/build_web_compilers.dart';

Builder devCompilerBuilder(_) => const DevCompilerBuilder();
Builder webEntrypointBuilder(BuilderOptions options) =>
    new WebEntrypointBuilder.fromOptions(options);
PostProcessBuilder dart2JsArchiveExtractor(_) => new Dart2JsArchiveExtractor();
PostProcessBuilder dartSourceCleanup(BuilderOptions options) =>
    (options.config['enabled'] as bool ?? false)
        ? const FileDeletingBuilder(const ['.dart'])
        : const FileDeletingBuilder(const ['.dart'], isEnabled: false);
