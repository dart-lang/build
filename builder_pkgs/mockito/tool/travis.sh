#!/bin/bash

# Fast fail the script on failures.
set -e

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  lib/mockito.dart \
  lib/mockito_no_mirrors.dart \
  lib/src/invocation_matcher.dart \
  test/mockito_test.dart

# Run the tests.
dart -c test/invocation_matcher_test.dart
dart -c test/mockito_test.dart
