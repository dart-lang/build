#!/bin/bash

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

pushd build_test
pub get
dartanalyzer --fatal-warnings lib/build_test.dart
pub run test
popd

pushd build
pub get
dartanalyzer --fatal-warnings lib/build.dart
pub run test

# Install dart_coveralls; gather and send coverage data.
if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "stable" ]; then
  dart tool/create_test_all.dart
  pub global activate dart_coveralls
  pub global run dart_coveralls report \
    --retry 2 \
    --exclude-test-files \
    tool/test_all.dart
  rm tool/test_all.dart
fi
popd
