// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

class MemberCountLibraryGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final topLevelVarCount = topLevelNumVariables(library).length;

    return '''
// Source library: ${library.element.source.uri}
const topLevelNumVarCount = $topLevelVarCount;
''';
  }
}
