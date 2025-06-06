// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

// TODO(davidmorgan): refactor overhead, hidden, ...
class PhaseProgress {
  final int inputs;

  AssetId? nextInput;

  Duration duration = Duration.zero;
  int skipped = 0;
  int builtNew = 0;
  int builtSame = 0;
  int builtNothing = 0;

  PhaseProgress({required this.inputs});

  bool get isOptional => inputs == 0;

  bool get isStarting => skipped + builtNew + builtSame + builtNothing == 0;

  bool get isFinished =>
      inputs == skipped + builtNew + builtSame + builtNothing;
}
