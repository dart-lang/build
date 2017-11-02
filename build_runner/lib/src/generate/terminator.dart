// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

/// Fires [shouldTerminate] once a `SIGINT` is intercepted.
///
/// The `SIGINT` stream can optionally be replaced with another Stream in the
/// constructor. [cancel] should be called after work is finished. If multiple
/// events are receieved on the terminate event stream before work is finished
/// the process will be terminated with [exit].
class Terminator {
  /// A Future that fires when a signal has been received indicating that builds
  /// should stop.
  final Future shouldTerminate;
  final StreamSubscription _subscription;

  factory Terminator([Stream terminateEventStream]) {
    var shouldTerminate = new Completer();
    terminateEventStream ??= ProcessSignal.SIGINT.watch();
    int numEventsSeen = 0;
    StreamSubscription terminateListener = terminateEventStream.listen((_) {
      numEventsSeen++;
      if (numEventsSeen == 1) {
        shouldTerminate.complete();
      } else {
        exit(2);
      }
    });
    return new Terminator._(shouldTerminate.future, terminateListener);
  }

  Terminator._(this.shouldTerminate, this._subscription);

  Future cancel() => _subscription.cancel();
}
