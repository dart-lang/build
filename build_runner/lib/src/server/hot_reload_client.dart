// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

final _buildUpdatesProtocol = r'$livereload';

main() {
  var webSocket =
      WebSocket('ws://' + window.location.host, [_buildUpdatesProtocol]);
  webSocket.onMessage.listen((MessageEvent e) {
    window.location.reload();
  });
}
