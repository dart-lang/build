// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library build.src.generate.phase;

import '../builder/builder.dart';
import 'input_set.dart';

/// A single phase in the build process. None of the [Builder]s in a single
/// phase should depend on any of the outputs of other [Builder]s in that same
/// phase. 
class Phase {
  /// The list of all [Builder]s that should be run on all [InputSet]s.
  final List<Builder> builders;

  /// The list of all [InputSet]s that should be used as primary inputs.
  final List<InputSet> inputSets;

  Phase(List<Builder> builders, List<InputSet> inputSets)
      : builders = new List.unmodifiable(builders),
        inputSets = new List.unmodifiable(inputSets);
}
