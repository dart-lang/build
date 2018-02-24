// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';

/// Parses command line args into a [BuilderOptions].
///
/// Arguments must be match any of the forms:
/// - `KEY`
/// - `KEY=VALUE`
/// - `--KEY`
/// - `--KEY=VALUE`
///
/// Values are JSON decoded when possible, and passed through directly as a
/// String when the JSON decode fails.
BuilderOptions optionsFromArgs(List<String> args) {
  args = new List.from(args);
  final options = <String, dynamic>{};
  for (final arg in args) {
    final withoutDash = arg.startsWith('--') ? arg.substring(2) : arg;
    final parts = withoutDash.split('=');

    if (parts.length > 2 || parts.first.isEmpty) {
      throw new ArgumentError('Could not parse argument $arg: $parts');
    }

    final option = parts.first;
    final value = parts.length == 2 ? _decode(parts[1]) : true;
    options[option] = value;
  }
  return new BuilderOptions(options);
}

dynamic _decode(String value) {
  try {
    return JSON.decode(value);
  } on FormatException {
    return value;
  }
}
