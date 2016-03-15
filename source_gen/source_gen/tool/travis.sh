#!/bin/bash

# Fast fail the script on failures.
set -e

# Skipping this until at least we have a dev release that aligns with dart_style version
# $(dirname -- "$0")/ensure_dartfmt.sh

# Run the tests.
pub run test

# Run the build.dart file - just to make sure it works
dart --checked tool/build.dart

# Install dart_coveralls; gather and send coverage data.
if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "stable" ]; then
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --retry 2 \
    --exclude-test-files \
    test/test_all.dart
fi
