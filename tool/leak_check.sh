#!/bin/bash --

# Checks for memory leaks.
#
# Runs many incremental builds, prints the average increase in memory usage
# per build.
#
# Exits with an error code if the hard-coded max leak size is exceeded.

# DO NOT SUBMIT
exit 0

if test -d build_runner_core; then
  cd build_runner_core
fi

dart test/invalidation/invalidation_leak_checker.dart setup

leak_amount=$(dart test/invalidation/invalidation_leak_checker.dart)
leak_limit=15000

if test $((leak_amount)) -gt "$leak_limit"; then
  echo "Measured leak size $leak_amount > $leak_limit, failing!"
  exit 1
else
  echo "Measured leak size $leak_amount < $leak_limit."
  exit 0
fi

# Measurement history
#
# Initial check-in:
#   52455, 52332, 52308
#
# Initial check-in with https://dart-review.googlesource.com/c/sdk/+/441740:
#   21482, 11568, 13186
#
# After `build_runner` leak fixes and analyzer 7.7.1 with 441740:
#   13147, 12515, 13320
