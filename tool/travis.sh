#!/bin/bash

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

pushd $PKG
pub upgrade
dartanalyzer --fatal-warnings .
if [ "$TRAVIS_DART_VERSION" == "dev" ]; then
  echo Any unformatted files?
  dartfmt -n --set-exit-if-changed .
fi
