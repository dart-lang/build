bool areSdkVersionsSame(String thisVersion, String thatVersion) {
  if (thisVersion == null || thatVersion == null) {
    return thisVersion == thatVersion;
  }

  return thisVersion.split(' ').first == thatVersion.split(' ').first;
}
