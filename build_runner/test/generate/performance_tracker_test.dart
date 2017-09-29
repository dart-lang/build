// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

import 'package:build_runner/src/generate/performance_tracker.dart';

main() {
  group('PerformanceTracker', () {
    BuildPerformanceTracker tracker;

    setUp(() {
      tracker = new BuildPerformanceTracker()..start();
    });

    test('can track start/stop times and total duration', () {
      tracker.stop();
      expect(tracker.startTime.microsecondsSinceEpoch,
          lessThan(new DateTime.now().microsecondsSinceEpoch));
      expect(
          tracker.stopTime.microsecondsSinceEpoch,
          allOf(lessThan(new DateTime.now().microsecondsSinceEpoch),
              greaterThan(tracker.startTime.microsecondsSinceEpoch)));
      expect(
          tracker.duration,
          new Duration(
              microseconds: tracker.stopTime.microsecondsSinceEpoch -
                  tracker.startTime.microsecondsSinceEpoch));
    });

    test('can track multiple actions', () async {
      var packages = ['a', 'b', 'c'];
      var buildActions =
          packages.map((p) => new BuildAction(new CopyBuilder(), p)).toList();
      for (var action in buildActions) {
        await tracker.trackAction(action, () async {
          await new Future.delayed(new Duration(milliseconds: 5));
          var package = action.inputSet.package;
          return [new AssetId(package, 'lib/$package.txt')];
        });
      }
      tracker.stop();

      expect(tracker.actions.map((trackedAction) => trackedAction.action),
          orderedEquals(buildActions));
      var last = tracker.startTime;
      var actionsTotal = new Duration(microseconds: 0);
      for (var trackedAction in tracker.actions) {
        actionsTotal += trackedAction.duration;
        expect(trackedAction.startTime.microsecondsSinceEpoch,
            greaterThan(last.microsecondsSinceEpoch));
        expect(trackedAction.stopTime.microsecondsSinceEpoch,
            greaterThan(trackedAction.startTime.microsecondsSinceEpoch));
        last = trackedAction.stopTime;
      }
      expect(tracker.stopTime.microsecondsSinceEpoch,
          greaterThan(last.microsecondsSinceEpoch));
      expect(actionsTotal, lessThanOrEqualTo(tracker.duration));
    });
  });
}
