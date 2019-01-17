// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'server_log.g.dart';

abstract class ServerLog implements Built<ServerLog, ServerLogBuilder> {
  static Serializer<ServerLog> get serializer => _$serverLogSerializer;

  factory ServerLog([updates(ServerLogBuilder b)]) = _$ServerLog;

  ServerLog._();
  String get log;
}
