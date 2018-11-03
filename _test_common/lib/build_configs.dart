// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';

Map<String, BuildConfig> parseBuildConfigs(
        Map<String, Map<String, dynamic>> configs) =>
    Map<String, BuildConfig>.fromIterable(configs.keys,
        value: (key) => BuildConfig.fromMap(key as String, [], configs[key]));
