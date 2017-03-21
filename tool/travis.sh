#!/bin/bash

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

pushd build_test
pub upgrade
dartanalyzer --fatal-warnings lib/build_test.dart
popd

pushd build
pub upgrade
dartanalyzer --fatal-warnings lib/build.dart
pub run test
popd

pushd build_runner
pub upgrade
dartanalyzer --fatal-warnings lib/build_runner.dart
pub run test
popd

pushd build_barback
pub upgrade
dartanalyzer --fatal-warnings lib/build_barback.dart
pub run test
popd
