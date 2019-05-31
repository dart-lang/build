#!/bin/bash
# Created with package:mono_repo v2.1.0

if [[ -z ${PKGS} ]]; then
  echo -e '\033[31mPKGS environment variable must be set!\033[0m'
  exit 1
fi

if [[ "$#" == "0" ]]; then
  echo -e '\033[31mAt least one task argument must be provided!\033[0m'
  exit 1
fi

EXIT_CODE=0

for PKG in ${PKGS}; do
  echo -e "\033[1mPKG: ${PKG}\033[22m"
  pushd "${PKG}" || exit $?
  pub upgrade --no-precompile || exit $?

  for TASK in "$@"; do
    echo
    echo -e "\033[1mPKG: ${PKG}; TASK: ${TASK}\033[22m"
    case ${TASK} in
    command_0)
      echo 'pub run build_runner test -- -p chrome'
      pub run build_runner test -- -p chrome || EXIT_CODE=$?
      ;;
    command_1)
      echo 'pub run build_runner test -- -p vm test/configurable_uri_test.dart'
      pub run build_runner test -- -p vm test/configurable_uri_test.dart || EXIT_CODE=$?
      ;;
    command_2)
      echo 'pub run build_runner test'
      pub run build_runner test || EXIT_CODE=$?
      ;;
    command_4)
      echo 'dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs-- -P presubmit'
      dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs-- -P presubmit || EXIT_CODE=$?
      ;;
    dartanalyzer_0)
      echo 'dartanalyzer --fatal-infos --fatal-warnings .'
      dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartanalyzer_1)
      echo 'dartanalyzer --fatal-warnings .'
      dartanalyzer --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartfmt)
      echo 'dartfmt -n --set-exit-if-changed .'
      dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
      ;;
    test_00)
      echo 'pub run test --total-shards 6 --shard-index 0'
      pub run test --total-shards 6 --shard-index 0 || EXIT_CODE=$?
      ;;
    test_01)
      echo 'pub run test --total-shards 6 --shard-index 1'
      pub run test --total-shards 6 --shard-index 1 || EXIT_CODE=$?
      ;;
    test_02)
      echo 'pub run test --total-shards 6 --shard-index 2'
      pub run test --total-shards 6 --shard-index 2 || EXIT_CODE=$?
      ;;
    test_03)
      echo 'pub run test --total-shards 6 --shard-index 3'
      pub run test --total-shards 6 --shard-index 3 || EXIT_CODE=$?
      ;;
    test_04)
      echo 'pub run test --total-shards 6 --shard-index 4'
      pub run test --total-shards 6 --shard-index 4 || EXIT_CODE=$?
      ;;
    test_05)
      echo 'pub run test --total-shards 6 --shard-index 5'
      pub run test --total-shards 6 --shard-index 5 || EXIT_CODE=$?
      ;;
    test_06)
      echo 'pub run test'
      pub run test || EXIT_CODE=$?
      ;;
    test_07)
      echo 'pub run test -x integration'
      pub run test -x integration || EXIT_CODE=$?
      ;;
    test_08)
      echo 'pub run test -t integration --total-shards 4 --shard-index 0'
      pub run test -t integration --total-shards 4 --shard-index 0 || EXIT_CODE=$?
      ;;
    test_09)
      echo 'pub run test -t integration --total-shards 4 --shard-index 1'
      pub run test -t integration --total-shards 4 --shard-index 1 || EXIT_CODE=$?
      ;;
    test_10)
      echo 'pub run test -t integration --total-shards 4 --shard-index 2'
      pub run test -t integration --total-shards 4 --shard-index 2 || EXIT_CODE=$?
      ;;
    test_11)
      echo 'pub run test -t integration --total-shards 4 --shard-index 3'
      pub run test -t integration --total-shards 4 --shard-index 3 || EXIT_CODE=$?
      ;;
    test_12)
      echo 'pub run test -x presubmit-only'
      pub run test -x presubmit-only || EXIT_CODE=$?
      ;;
    test_13)
      echo 'pub run test -t presubmit-only --run-skipped'
      pub run test -t presubmit-only --run-skipped || EXIT_CODE=$?
      ;;
    *)
      echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
      EXIT_CODE=1
      ;;
    esac
  done

  popd
done

exit ${EXIT_CODE}
