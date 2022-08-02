// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

List<int> protoToDelimitedBuffer(GeneratedMessage message) {
  var messageBuffer = CodedBufferWriter();
  message.writeToCodedBufferWriter(messageBuffer);

  var delimiterBuffer = CodedBufferWriter();
  delimiterBuffer.writeInt32NoTag(messageBuffer.lengthInBytes);

  var result =
      Uint8List(messageBuffer.lengthInBytes + delimiterBuffer.lengthInBytes);

  delimiterBuffer.writeTo(result);
  messageBuffer.writeTo(result, delimiterBuffer.lengthInBytes);

  return result;
}
