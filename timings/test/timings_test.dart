// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:timings/src/clock.dart';
import 'package:timings/timings.dart';

main() {
  DateTime time;
  final startTime = DateTime(2017);
  DateTime fakeClock() => /*DateTime.now()*/ time;

  TimeTracker tracker;

  T scopedTrack<T>(T f()) => scopeClock(fakeClock, () => tracker.track(f));

  setUp(() {
    time = startTime;
  });

  canHandleSync(additionalExpects()) {
    test('Can track sync code', () {
      scopedTrack(() {
        time = time.add(const Duration(seconds: 5));
      });
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can track handled sync exceptions', () async {
      scopedTrack(() {
        try {
          time = time.add(const Duration(seconds: 4));
          throw 'error';
        } on String {
          time = time.add(const Duration(seconds: 1));
        }
      });
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can track in case of unhandled sync exceptions', () async {
      expect(
          () => scopedTrack(() {
                time = time.add(const Duration(seconds: 5));
                throw 'error';
              }),
          throwsA(TypeMatcher<String>()));
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });
  }

  canHandleAsync(additionalExpects()) {
    test('Can track async code', () async {
      await scopedTrack(() => Future(() {
            time = time.add(const Duration(seconds: 5));
          }));
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
      additionalExpects();
    });

    test('Can track handled async exceptions', () async {
      await scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        return Future(() {
          time = time.add(const Duration(seconds: 2));
          throw 'error';
        }).then((_) {
          time = time.add(const Duration(seconds: 4));
        }).catchError((error, stack) {
          time = time.add(const Duration(seconds: 8));
        });
      });
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 11));
      additionalExpects();
    });

    test('Can track in case of unhandled async exceptions', () async {
      var future = scopedTrack(() {
        time = time.add(const Duration(seconds: 1));
        return Future(() {
          time = time.add(const Duration(seconds: 2));
          throw 'error';
        }).then((_) {
          time = time.add(const Duration(seconds: 4));
        });
      });
      await expectLater(future, throwsA(TypeMatcher<String>()));
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 3));
      additionalExpects();
    });
  }

  group('SyncTimeTracker', () {
    setUp(() {
      tracker = SyncTimeTracker();
    });

    canHandleSync(() {});

    test('Can not track async code', () async {
      await scopedTrack(() => Future(() {
            time = time.add(const Duration(seconds: 5));
          }));
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, startTime);
      expect(tracker.duration, const Duration(seconds: 0));
    });
  });

  group('SyncTimeTracker.kindaAsync', () {
    setUp(() {
      tracker = SyncTimeTracker.kindaAsync();
    });

    canHandleSync(() {});

    canHandleAsync(() {});

    test('Can not distinguish own async code', () async {
      var future = scopedTrack(() => Future(() {
            time = time.add(const Duration(seconds: 5));
          }));
      time = time.add(const Duration(seconds: 10));
      await future;
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 15));
    });
  });

  group('AsyncTimeTracker', () {
    AsyncTimeTracker asyncTracker;
    setUp(() {
      tracker = asyncTracker = AsyncTimeTracker();
    });

    canHandleSync(() {
      expect(asyncTracker.innerDuration, asyncTracker.duration);
      expect(asyncTracker.slices.length, 1);
    });

    canHandleAsync(() {
      expect(asyncTracker.innerDuration, asyncTracker.duration);
      expect(asyncTracker.slices.length, greaterThan(1));
    });

    test('Can track complex async innerDuration', () async {
      var future = scopedTrack(() {
        time = time.add(const Duration(seconds: 1)); // Tracked sync
        return Future(() {
          time = time.add(const Duration(seconds: 2)); // Tracked async
        }).then((_) async {
          await Future.delayed(Duration.zero);
          time = time.add(const Duration(seconds: 4)); // Tracked async, delayed
        });
      }).then((_) {
        time = time.add(const Duration(seconds: 8)); // Async, after tracking
      });
      time = time.add(const Duration(seconds: 16)); // Sync, inside tracking
      await Future.wait([
        future,
        // Async, inside tracking
        Future.microtask(() => time = time.add(const Duration(seconds: 32)))
      ]);
      expect(asyncTracker.startTime, startTime);
      expect(asyncTracker.stopTime.millisecondsSinceEpoch,
          lessThan(time.millisecondsSinceEpoch));
      expect(asyncTracker.duration, const Duration(seconds: 55));
      expect(asyncTracker.innerDuration, const Duration(seconds: 7));
      expect(asyncTracker.slices.length, greaterThan(1));
    });
  });
}
