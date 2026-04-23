// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:yaml/yaml.dart';

class Pubspecs {
  static YamlMap load(String path) {
    final pubspec = File(path);
    if (!pubspec.existsSync()) {
      throw StateError('Unable to load packages, no `$path` found.');
    }
    return loadYaml(pubspec.readAsStringSync()) as YamlMap;
  }
}
