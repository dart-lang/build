// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'continue_request.g.dart';

/// A request to continue building while the daemon is in `step` mode.
abstract class ContinueRequest
    implements Built<ContinueRequest, ContinueRequestBuilder> {
  static Serializer<ContinueRequest> get serializer =>
      _$continueRequestSerializer;

  factory ContinueRequest([Function(ContinueRequestBuilder b) updates]) =
      _$ContinueRequest;

  ContinueRequest._();
}
