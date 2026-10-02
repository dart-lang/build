// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_contract_weaver/src/cli/contract_weaver_command.dart';

Future<void> main(List<String> args) async {
  exitCode = await ContractWeaverCommand().run(args);
}
