#!/bin/bash

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

function run_coveralls {
  if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "stable" ]; then
    dart tool/create_test_all.dart
    pub global activate dart_coveralls
    pub global run dart_coveralls report \
      --retry 2 \
      --exclude-test-files \
      tool/test_all.dart
    rm tool/test_all.dart
  fi
}

pushd build_test
pub upgrade
dartanalyzer --fatal-warnings lib/build_test.dart
popd

pushd build
pub upgrade
dartanalyzer --fatal-warnings lib/build.dart
pub run test
run_coveralls
popd

pushd build_runner
pub upgrade
dartanalyzer --fatal-warnings lib/build_runner.dart
pub run test
run_coveralls
popd

pushd build_barback
pub upgrade
dartanalyzer --fatal-warnings lib/build_barback.dart
pub run test
run_coveralls
popd

pushd bazel_codegen
pub upgrade
dartanalyzer --fatal-warnings lib/bazel_codegen.dart
pub run test
popd
