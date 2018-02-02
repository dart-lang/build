// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  print('''

Oops! build_runner only supports automatic build scripts on >0.7.0, which
requires the pre-release 2.0 dart SDK.

Your SDK version is:

${Platform.version}
''');
}
