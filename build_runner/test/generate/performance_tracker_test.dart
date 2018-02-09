// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_runner/src/generate/phase.dart';
import 'package:build_runner/src/util/clock.dart';
import 'package:build_test/build_test.dart';

import 'package:build_runner/src/generate/performance_tracker.dart';

main() {
  group('PerformanceTracker', () {
    DateTime time;
    final startTime = new DateTime(2017);
    final Clock fakeClock = () => time;

    BuildPerformanceTracker tracker;

    setUp(() {
      time = startTime;
      tracker = scopeClock(
        fakeClock,
        () => new BuildPerformanceTracker()..start(),
      );
    });

    test('can track start/stop times and total duration', () {
      time = startTime.add(const Duration(seconds: 5));
      scopeClock(fakeClock, tracker.stop);
      expect(tracker.startTime, startTime);
      expect(tracker.stopTime, time);
      expect(tracker.duration, const Duration(seconds: 5));
    });

    test('can track multiple actions', () async {
      await scopeClock(fakeClock, () async {
        var packages = ['a', 'b', 'c'];
        var builder = new TestBuilder();
        var actions = packages.map((p) => new BuildAction(builder, p)).toList();

        for (var action in actions) {
          time = time.add(const Duration(seconds: 5));
          var package = action.package;
          return [new AssetId(package, 'lib/$package.txt')];
        }

        tracker.stop();
        expect(tracker.phases.map((a) => a.action), orderedEquals(actions));

        var times = tracker.actions.map((t) => t.stopTime).toList();
        expect(times.toSet(), hasLength(times), reason: 'Expected unique time');
        expect(times, orderedEquals(times.toList()..sort()));

        var total = tracker.actions.fold(0, (a, b) => a.duration + b.duration);
        expect(total, const Duration(seconds: 15));
      });
    });
  });
}
