# International Space Station (ISS) library

This library accesses the International Space Station's APIs
(using [package:http](https://pub.dartlang.org/packages/http))
to fetch the space station's current location.

The unit tests for this library use package:mockito to generate
preset values for the space station's location,
and package:test to create reproducible scenarios to verify the
expected outcome.

The ISS library, `iss.dart`, consists of two classes:

**IssLocator**
: Fetches the current GPS position directly under the space station.

**IssSpotter**
: Performs calculations from the observer's location on earth.

---

## Testing

The unit test, `iss_dart.test`, mocks the IssLocator class:

```
// The Mock class uses noSuchMethod to catch all method invocations.
class MockIssLocator extends Mock implements IssLocator {}
```
The tests check for two scenarios:

**Spherical distance**
: Given two predefined points on earth, verify the calculated distance
between them.

```
  group('Spherical distance', () {
    test('London - Paris', () {
      Point<double> london = new Point(51.5073, -0.1277);
      Point<double> paris = new Point(48.8566, 2.3522);
      double d = sphericalDistanceKm(london, paris);
      // London should be approximately 343.5km
      // (+/- 0.1km) from Paris.
      expect(d, closeTo(343.5, 0.1));
    });

    test('San Francisco - Mountain View', () {
      Point<double> sf = new Point(37.783333, -122.416667);
      Point<double> mtv = new Point(37.389444, -122.081944);
      double d = sphericalDistanceKm(sf, mtv);
      // San Francisco should be approximately 52.8km
      // (+/- 0.1km) from Mountain View.
      expect(d, closeTo(52.8, 0.1));
    });
  });
```

**ISS Spotter**
: Stubs `IssLocator.currentPosition` using `when().thenReturn()`.
Evaluate whether the space station (using a predefined location)
is visible from a second predefined location.
This test runs asynchronously.

```
  group('ISS spotter', () {
    test('ISS visible', () async {
      Point<double> sf = new Point(37.783333, -122.416667);
      Point<double> mtv = new Point(37.389444, -122.081944);
      IssLocator locator = new MockIssLocator();
      // Mountain View should be visible from San Francisco.
      when(locator.currentPosition).thenReturn(sf);

      var spotter = new IssSpotter(locator, mtv);
      expect(spotter.isVisible, true);
    });

    test('ISS not visible', () async {
      Point<double> london = new Point(51.5073, -0.1277);
      Point<double> mtv = new Point(37.389444, -122.081944);
      IssLocator locator = new MockIssLocator();
      // London should not be visible from Mountain View.
      when(locator.currentPosition).thenReturn(london);

      var spotter = new IssSpotter(locator, mtv);
      expect(spotter.isVisible, false);
    });
  });
```

---

## Files

* [iss.dart](https://raw.githubusercontent.com/dart-lang/mockito/master/test/example/iss/iss.dart)
: International space station API library

* [iss_test.dart](https://raw.githubusercontent.com/dart-lang/mockito/master/test/example/iss/iss_test.dart)
: Unit tests for iss.dart library


