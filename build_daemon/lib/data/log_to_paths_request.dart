// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'log_to_paths_request.g.dart';

abstract class LogToPathsRequest
    implements Built<LogToPathsRequest, LogToPathsRequestBuilder> {
  static Serializer<LogToPathsRequest> get serializer =>
      _$logToPathsRequestSerializer;

  factory LogToPathsRequest([updates(LogToPathsRequestBuilder b)]) =
      _$LogToPathsRequest;

  LogToPathsRequest._();

  BuiltList<String> get paths;
}
