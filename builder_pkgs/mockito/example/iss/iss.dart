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

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';

/// Provides the International Space Station's current GPS position.
class IssLocator {
  final Client client;

  Point<double> _position;
  Future _ongoingRequest;

  IssLocator(this.client);

  Point<double> get currentPosition => _position;

  /// Returns the current GPS position in [latitude, longitude] format.
  Future update() async {
    _ongoingRequest ??= _doUpdate();
    await _ongoingRequest;
    _ongoingRequest = null;
  }

  Future _doUpdate() async {
    // Returns the point on the earth directly under the space station
    // at this moment.
    var rs = await client.get('http://api.open-notify.org/iss-now.json');
    var data = jsonDecode(rs.body);
    var latitude = double.parse(data['iss_position']['latitude'] as String);
    var longitude = double.parse(data['iss_position']['longitude'] as String);
    _position = Point<double>(latitude, longitude);
  }
}

// Performs calculations from the observer's location on earth.
class IssSpotter {
  final IssLocator locator;
  final Point<double> observer;
  final String label;

  IssSpotter(this.locator, this.observer, {this.label});

  // The ISS is defined to be visible if the distance from the observer to
  // the point on the earth directly under the space station is less than 80km.
  bool get isVisible {
    var distance = sphericalDistanceKm(locator.currentPosition, observer);
    return distance < 80.0;
  }
}

// Returns the distance, in kilometers, between p1 and p2 along the earth's
// curved surface.
double sphericalDistanceKm(Point<double> p1, Point<double> p2) {
  var dLat = _toRadian(p1.x - p2.x);
  var sLat = pow(sin(dLat / 2), 2);
  var dLng = _toRadian(p1.y - p2.y);
  var sLng = pow(sin(dLng / 2), 2);
  var cosALat = cos(_toRadian(p1.x));
  var cosBLat = cos(_toRadian(p2.x));
  var x = sLat + cosALat * cosBLat * sLng;
  var d = 2 * atan2(sqrt(x), sqrt(1 - x)) * _radiusOfEarth;
  return d;
}

/// Radius of the earth in km.
const int _radiusOfEarth = 6371;
double _toRadian(num degree) => degree * pi / 180.0;
