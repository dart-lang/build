// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// A simple builder which globs files in a package and outputs a file that
/// lists each matching file in alphabetical order into another file, one
/// per line.
class GlobbingBuilder extends Builder {
  @override
  final buildExtensions = {
    '.globPlaceholder': ['.matchingFiles'],
  };

  final Glob glob;

  GlobbingBuilder(this.glob);

  @override
  Future build(BuildStep buildStep) async {
    var allAssets = await buildStep.findAssets(glob).toList();
    allAssets.sort((a, b) => a.path.compareTo(b.path));
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.matchingFiles'),
        allAssets.map((id) => id.toString()).join('\n'));
  }
}
