#!/bin/bash --

# Checks that the contract clauses in `build_runner` still compile.
#
# Clauses live in annotation strings, so the analyzer never sees them: a clause
# naming a parameter that has since been renamed is invisible until something
# weaves it in. This weaves the clauses into a throwaway copy of the package and
# analyzes that copy, where a rotten clause is an undefined name.
#
# Tests are not run. Running the woven test suite finds more, and takes far
# longer.

set -e

cd "$(dirname "$0")/../test_infra/_contract_weaver"

exec dart run bin/run_with_contracts.dart \
  --package=build_runner \
  --analyze-only \
  --contract-import=.isBrOutput,.sharedPartId,.sharedPartLibraryId,.isBrSharedPart=package:build_runner/src/build/br_outputs.dart
