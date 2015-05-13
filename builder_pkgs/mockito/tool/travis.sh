#!/bin/bash

# Fast fail the script on failures.
set -e

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  lib/mockito.dart \
  test/mockito_test.dart

# Run the tests.
dart test/mockito_test.dart

