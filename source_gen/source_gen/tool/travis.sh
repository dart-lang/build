#!/bin/bash

# Fast fail the script on failures.   
set -e

# Run the tests.
dart --checked test/test_all.dart

# Run the build.dart file - just to make sure it works
dart --checked build.dart

# Install dart_coveralls; gather and send coverage data.
if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "stable" ]; then
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --token $COVERALLS_TOKEN \
    --retry 2 \
    --exclude-test-files \
    test/test_all.dart
fi