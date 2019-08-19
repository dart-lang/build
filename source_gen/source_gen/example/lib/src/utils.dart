// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Returns all [TopLevelVariableElement] members in [reader]'s library that
/// have a type of [num].
Iterable<TopLevelVariableElement> topLevelNumVariables(LibraryReader reader) =>
    reader.allElements
        .whereType<TopLevelVariableElement>()
        .where((element) => element.type
            // TODO: migrate to supported API when min pkg:analyzer is bumped
            // ignore: deprecated_member_use
            .isAssignableTo(reader.element.context.typeProvider.numType));
