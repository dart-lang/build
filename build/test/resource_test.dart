// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library;

import 'dart:async';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  late ResourceManager resourceManager;
  setUp(() {
    resourceManager = ResourceManager();
  });

  tearDown(() async {
    await resourceManager.disposeAll();
  });

  group('ResourceManager', () {
    test('gives the same instance until disposed', () async {
      var last = 0;
      final intResource = Resource(() => last++);
      final first = await resourceManager.fetch(intResource);
      expect(first, 0);
      final second = await resourceManager.fetch(intResource);
      expect(second, first);
      await resourceManager.disposeAll();
      final third = await resourceManager.fetch(intResource);
      expect(third, 1);
    });

    test('reuses instances when a dispose can clean the state', () async {
      var last = 0;
      final intResource = Resource(
        () => last++,
        dispose: expectAsync1((int instance) {
          expect(instance, last - 1);
        }, max: -1),
      );
      final first = await resourceManager.fetch(intResource);
      expect(first, 0);
      await resourceManager.disposeAll();
      final second = await resourceManager.fetch(intResource);
      expect(second, 0);
    });

    group('on failure', () {
      final logs = <LogRecord>[];
      setUp(() {
        logs.clear();
        final sub = Logger.root.onRecord.listen(logs.add);
        addTearDown(sub.cancel);
      });

      for (final (type, dispose) in [
        ('sync', (_) => throw StateError('fail')),
        ('async', (_) async => throw StateError('fail')),
      ]) {
        test('discards instance and logs if $type dispose throws', () async {
          final resource = Resource(Object.new, dispose: dispose);
          final first = await resourceManager.fetch(resource);
          await resourceManager.disposeAll();
          expect(logs.single.message, contains('Error disposing resource'));
          expect(await resourceManager.fetch(resource), isNot(same(first)));
        });
      }

      test('discards instance without logging if create throws', () async {
        var throws = true;
        final resource = Resource(
          () => throws ? throw StateError('fail') : Object(),
          dispose: (_) {},
        );
        await expectLater(
          resourceManager.fetch(resource),
          throwsA(isA<StateError>()),
        );
        await resourceManager.disposeAll();
        expect(logs, isEmpty);
        throws = false;
        expect(await resourceManager.fetch(resource), isA<Object>());
      });
    });

    test('can asynchronously get resources', () async {
      var last = 0;
      final intResource = Resource(() => Future.value(++last));
      final actual = await resourceManager.fetch(intResource);
      expect(actual, last);
    });

    test('can asynchronously dispose resources', () async {
      var disposed = false;
      final intResource = Resource(
        () => 0,
        dispose: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          disposed = true;
        },
      );
      await resourceManager.fetch(intResource);
      await resourceManager.disposeAll();
      expect(disposed, true);
    });

    test('can fetch and dispose multiple resources', () async {
      var numDisposed = 0;
      final length = 10;
      final resources = List<Resource<int>>.generate(
        length,
        (i) => Resource(
          () => i,
          dispose: (instance) {
            expect(instance, i);
            numDisposed++;
          },
        ),
      );
      final values = await Future.wait(
        resources.map((r) => resourceManager.fetch(r)),
      );
      expect(values, List<int>.generate(length, (i) => i));
      await resourceManager.disposeAll();
      expect(numDisposed, length);
    });

    test('doesn\'t share resources with other ResourceManagers', () async {
      final otherManager = ResourceManager();
      var last = 0;
      final intResource = Resource(() => last++);

      final original = await resourceManager.fetch(intResource);
      final other = await otherManager.fetch(intResource);
      expect(original, isNot(other));
    });
  });
}
