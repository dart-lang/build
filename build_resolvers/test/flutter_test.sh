#!/bin/bash

# Fast fail the script on failures.
set -ex

# Get Flutter.
echo "Cloning master Flutter branch"
git clone https://github.com/flutter/flutter.git ./flutter

./flutter/bin/cache/dart-sdk/bin/dart test/resolver_test
