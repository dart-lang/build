// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/data/client_options.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_client_options_request.g.dart';

abstract class SetClientOptionsRequest
    implements Built<SetClientOptionsRequest, SetClientOptionsRequestBuilder> {
  static Serializer<SetClientOptionsRequest> get serializer =>
      _$setClientOptionsRequestSerializer;

  factory SetClientOptionsRequest(
          [void Function(SetClientOptionsRequestBuilder) b]) =
      _$SetClientOptionsRequest;

  SetClientOptionsRequest._();

  ClientOptions get options;
}
