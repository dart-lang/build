// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/constants.dart';
import 'package:path/path.dart' as p;

String assetServerPortFilePath(String workingDirectory) =>
    p.join(daemonWorkspace(workingDirectory), '.asset_server_port');
