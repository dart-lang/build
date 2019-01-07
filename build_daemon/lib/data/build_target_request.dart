// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_target_request.g.dart';

abstract class BuildTargetRequest
    implements Built<BuildTargetRequest, BuildTargetRequestBuilder> {
  static Serializer<BuildTargetRequest> get serializer =>
      _$buildTargetRequestSerializer;

  factory BuildTargetRequest([updates(BuildTargetRequestBuilder b)]) =
      _$BuildTargetRequest;

  BuildTargetRequest._();

  BuiltList<String> get blackListPattern;
  String get target;
}
