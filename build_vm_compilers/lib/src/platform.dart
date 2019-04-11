// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_modules/build_modules.dart';

final vmPlatform = DartPlatform.register('vm', [
  'async',
  'cli',
  'collection',
  'convert',
  'core',
  'developer',
  'io',
  'isolate',
  'math',
  'mirrors',
  'nativewrappers',
  'profiler',
  'typed_data',
  'vmservice_io',
  '_internal',
]);
