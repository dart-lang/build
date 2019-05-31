// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'message.dart'
    if (dart.library.io) 'message_io.dart'
    if (dart.library.html) 'message_html.dart';
