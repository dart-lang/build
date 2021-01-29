// Copyright 2017 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'iss.dart';

// The Mock class uses noSuchMethod to catch all method invocations.
class MockIssLocator extends Mock implements IssLocator {}

void main() {
  // Given two predefined points on earth,
  // verify the calculated distance between them.
  group('Spherical distance', () {
    test('London - Paris', () {
      var london = Point(51.5073, -0.1277);
      var paris = Point(48.8566, 2.3522);
      var d = sphericalDistanceKm(london, paris);
      // London should be approximately 343.5km
      // (+/- 0.1km) from Paris.
      expect(d, closeTo(343.5, 0.1));
    });

    test('San Francisco - Mountain View', () {
      var sf = Point(37.783333, -122.416667);
      var mtv = Point(37.389444, -122.081944);
      var d = sphericalDistanceKm(sf, mtv);
      // San Francisco should be approximately 52.8km
      // (+/- 0.1km) from Mountain View.
      expect(d, closeTo(52.8, 0.1));
    });
  });

  // Stubs IssLocator.currentPosition() using when().thenReturn().
  // Calling currentPosition() then returns the predefined location
  // for the space station.
  // Evaluate whether the space station is visible from a
  // second predefined location. This test runs asynchronously.
  group('ISS spotter', () {
    test('ISS visible', () async {
      var sf = Point(37.783333, -122.416667);
      var mtv = Point(37.389444, -122.081944);
      IssLocator locator = MockIssLocator();
      // Mountain View should be visible from San Francisco.
      when(locator.currentPosition).thenReturn(sf);

      var spotter = IssSpotter(locator, mtv);
      expect(spotter.isVisible, true);
    });

    test('ISS not visible', () async {
      var london = Point(51.5073, -0.1277);
      var mtv = Point(37.389444, -122.081944);
      IssLocator locator = MockIssLocator();
      // London should not be visible from Mountain View.
      when(locator.currentPosition).thenReturn(london);

      var spotter = IssSpotter(locator, mtv);
      expect(spotter.isVisible, false);
    });
  });
}
