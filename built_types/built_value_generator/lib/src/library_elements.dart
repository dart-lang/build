// Copyright (c) 2016, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
// `ExperimentStatus` is needed to check language features and the analyzer
// does not export it.
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/experiments.dart';

/// Tools for [LibraryElement]s.
class LibraryElements {
  static bool areClassMixinsEnabled(LibraryElement element) =>
      ExperimentStatus.knownFeatures.containsKey('class-modifiers') &&
      element.featureSet.isEnabled(
        ExperimentStatus.knownFeatures['class-modifiers']!,
      );
}
