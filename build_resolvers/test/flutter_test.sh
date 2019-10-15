#!/bin/bash

# Fast fail the script on failures.
set -e

# Get Flutter.
echo "Cloning master Flutter branch"
git clone https://github.com/flutter/flutter.git ./flutter

if [[ $TRAVIS_OS_NAME == "windows" ]]; then
  ./flutter/bin/flutter.bat precache
else
  ./flutter/bin/flutter precache
fi

./flutter/bin/cache/dart-sdk/bin/dart test/resolver_test.dart

rm -rf ./flutter
