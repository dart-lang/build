// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

class PropertyProductGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final productNames = topLevelNumVariables(library)
        .map((element) => element.name)
        .join(' * ');

    return '''
num allProduct() => $productNames;
''';
  }
}
