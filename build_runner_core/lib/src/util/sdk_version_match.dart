import 'package:pub_semver/pub_semver.dart';

bool areSdkVersionsSame(String thisVersion, String thatVersion) {
  if (thisVersion == null || thatVersion == null) {
    return false;
  }

  try {
    return new Version.parse(thisVersion.split(' ').first) ==
        new Version.parse(thatVersion.split(' ').first);
  } on FormatException {
    return thisVersion == thatVersion;
  }
}
