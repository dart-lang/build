// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

class BuildLogPrinter {
  final bool verbose;
  final bool assumeTty;

  BuildLogPrinter({required this.verbose, bool? assumeTty})
    : assumeTty = assumeTty ?? false {
    Logger.root.level = Level.ALL;
  }

  void onData(LogRecord record) {
    print(record.message);
  }
}
