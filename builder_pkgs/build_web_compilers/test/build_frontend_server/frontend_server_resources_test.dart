// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_web_compilers/src/build_frontend_server/frontend_server_resources.dart';
import 'package:test/test.dart';

void main() {
  group('FrontendServerState.runSharedCompilation', () {
    final entrypoint = AssetId('a', 'web/main.dart');
    late FrontendServerState state;

    setUp(() {
      state = FrontendServerState();
    });

    test('runs compilations one at a time, in order', () async {
      final log = <String>[];
      final first = Completer<void>();
      final compilations = [
        state.runSharedCompilation(entrypoint, () async {
          log.add('first started');
          await first.future;
          log.add('first done');
        }),
        state.runSharedCompilation(entrypoint, () async {
          log.add('second started');
        }),
      ];
      await pumpEventQueue();
      expect(log, ['first started']);

      first.complete();
      await Future.wait(compilations);
      expect(log, ['first started', 'first done', 'second started']);
    });

    // `build_runner` runs every build step in its own error zone, and a
    // future's error doesn't cross error zones. If the second step awaited the
    // failed compilation of the first, it would never complete.
    test('runs a compilation after one that failed in another error zone', () {
      final firstStarted = Completer<void>();
      final failFirst = Completer<void>();
      final firstError = Completer<Object>();
      runZonedGuarded(() async {
        try {
          await state.runSharedCompilation(entrypoint, () async {
            firstStarted.complete();
            await failFirst.future;
            throw StateError('compile failed');
          });
        } catch (e) {
          firstError.complete(e);
        }
      }, (_, _) {});

      final secondRan = Completer<void>();
      runZonedGuarded(() async {
        await firstStarted.future;
        final second = state.runSharedCompilation(entrypoint, () async {});
        failFirst.complete();
        await second;
        secondRan.complete();
      }, (_, _) {});

      expect(firstError.future, completion(isStateError));
      expect(secondRan.future, completes);
    });
  });
}
