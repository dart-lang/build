// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'build_options_request.dart';
import 'build_request.dart';
import 'build_status.dart';
import 'build_target_request.dart';
import 'log_to_paths_request.dart';
import 'server_log.dart';

part 'serializers.g.dart';

/// Serializers for all the types used in Dart Build Daemon communication.
@SerializersFor([
  BuildRequest,
  BuildStatus,
  BuildResult,
  BuildResults,
  BuildTargetRequest,
  BuildOptionsRequest,
  LogToPathsRequest,
  ServerLog,
])
final Serializers serializers = _$serializers;
