// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

const Symbol logKey = #buildLog;

final _default = Logger('build.fallback');

/// The log instance for the currently running BuildStep.
///
/// Will be `null` when not running within a build.
Logger get log => Zone.current[logKey] as Logger? ?? _default;
