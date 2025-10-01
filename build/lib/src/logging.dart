// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

const Symbol logKey = #buildLog;

final _default = Logger('build.fallback');

/// `Logger` for use by a builder to log to the main `build_runner` output.
///
/// `build_runner` distinguishes three categories of log record:
///
/// Below [Level.WARNING] is called "info".
///
/// Info is only shown if `--verbose` was explicitly requested on the command
/// line.
///
/// At [Level.WARNING] but below [Level.SEVERE] is called a "warning".
///
/// Warnings are always shown, and the final build status will indicate that
/// the build completed with warnings.
///
/// At or above [Level.SEVERE] is an "error".
///
/// Errors signal that the build step has failed: build steps that depend on the
/// outputs will not run, and the build status will say the build failed.
///
/// If a builder throws an exception then it is logged as an error.
Logger get log => Zone.current[logKey] as Logger? ?? _default;
