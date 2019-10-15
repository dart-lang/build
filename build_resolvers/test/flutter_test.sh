#!/bin/bash

# Fast fail the script on failures.
set -e

# Get Flutter.
echo "Cloning master Flutter branch"
git clone https://github.com/flutter/flutter.git ./flutter

./flutter/bin/flutter config --no-analytics

./flutter/bin/cache/dart-sdk/bin/dart test/resolver_test.dart

rm -rf ./flutter
