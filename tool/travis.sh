#!/bin/bash
# Created with package:mono_repo v2.0.0-dev

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
  pushd ${PKG} || exit $?
  pub upgrade --no-precompile || exit $?

  for TASK in "$@"; do
    case ${TASK} in
    command_0) echo
      echo -e '\033[1mTASK: command_0\033[22m'
      echo -e 'pub run build_runner test -- -p chrome'
      pub run build_runner test -- -p chrome || EXIT_CODE=$?
      ;;
    command_1) echo
      echo -e '\033[1mTASK: command_1\033[22m'
      echo -e 'pub run build_runner test -- -p vm test/config_specific_import_test.dart'
      pub run build_runner test -- -p vm test/config_specific_import_test.dart || EXIT_CODE=$?
      ;;
    command_2) echo
      echo -e '\033[1mTASK: command_2\033[22m'
      echo -e 'pub run build_runner test'
      pub run build_runner test || EXIT_CODE=$?
      ;;
    command_3) echo
      echo -e '\033[1mTASK: command_3\033[22m'
      echo -e 'dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs'
      dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs || EXIT_CODE=$?
      ;;
    command_5) echo
      echo -e '\033[1mTASK: command_5\033[22m'
      echo -e 'dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs-- -P presubmit'
      dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs-- -P presubmit || EXIT_CODE=$?
      ;;
    dartanalyzer_0) echo
      echo -e '\033[1mTASK: dartanalyzer_0\033[22m'
      echo -e 'dartanalyzer --fatal-infos --fatal-warnings .'
      dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartanalyzer_1) echo
      echo -e '\033[1mTASK: dartanalyzer_1\033[22m'
      echo -e 'dartanalyzer --fatal-warnings .'
      dartanalyzer --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartfmt) echo
      echo -e '\033[1mTASK: dartfmt\033[22m'
      echo -e 'dartfmt -n --set-exit-if-changed .'
      dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
      ;;
    test_00) echo
      echo -e '\033[1mTASK: test_00\033[22m'
      echo -e 'pub run test --total-shards 6 --shard-index 0'
      pub run test --total-shards 6 --shard-index 0 || EXIT_CODE=$?
      ;;
    test_01) echo
      echo -e '\033[1mTASK: test_01\033[22m'
      echo -e 'pub run test --total-shards 6 --shard-index 1'
      pub run test --total-shards 6 --shard-index 1 || EXIT_CODE=$?
      ;;
    test_02) echo
      echo -e '\033[1mTASK: test_02\033[22m'
      echo -e 'pub run test --total-shards 6 --shard-index 2'
      pub run test --total-shards 6 --shard-index 2 || EXIT_CODE=$?
      ;;
    test_03) echo
      echo -e '\033[1mTASK: test_03\033[22m'
      echo -e 'pub run test --total-shards 6 --shard-index 3'
      pub run test --total-shards 6 --shard-index 3 || EXIT_CODE=$?
      ;;
    test_04) echo
      echo -e '\033[1mTASK: test_04\033[22m'
      echo -e 'pub run test --total-shards 6 --shard-index 4'
      pub run test --total-shards 6 --shard-index 4 || EXIT_CODE=$?
      ;;
    test_05) echo
      echo -e '\033[1mTASK: test_05\033[22m'
      echo -e 'pub run test --total-shards 6 --shard-index 5'
      pub run test --total-shards 6 --shard-index 5 || EXIT_CODE=$?
      ;;
    test_06) echo
      echo -e '\033[1mTASK: test_06\033[22m'
      echo -e 'pub run test'
      pub run test || EXIT_CODE=$?
      ;;
    test_07) echo
      echo -e '\033[1mTASK: test_07\033[22m'
      echo -e 'pub run test -x integration'
      pub run test -x integration || EXIT_CODE=$?
      ;;
    test_08) echo
      echo -e '\033[1mTASK: test_08\033[22m'
      echo -e 'pub run test -t integration --total-shards 4 --shard-index 0'
      pub run test -t integration --total-shards 4 --shard-index 0 || EXIT_CODE=$?
      ;;
    test_09) echo
      echo -e '\033[1mTASK: test_09\033[22m'
      echo -e 'pub run test -t integration --total-shards 4 --shard-index 1'
      pub run test -t integration --total-shards 4 --shard-index 1 || EXIT_CODE=$?
      ;;
    test_10) echo
      echo -e '\033[1mTASK: test_10\033[22m'
      echo -e 'pub run test -t integration --total-shards 4 --shard-index 2'
      pub run test -t integration --total-shards 4 --shard-index 2 || EXIT_CODE=$?
      ;;
    test_11) echo
      echo -e '\033[1mTASK: test_11\033[22m'
      echo -e 'pub run test -t integration --total-shards 4 --shard-index 3'
      pub run test -t integration --total-shards 4 --shard-index 3 || EXIT_CODE=$?
      ;;
    test_12) echo
      echo -e '\033[1mTASK: test_12\033[22m'
      echo -e 'pub run test -x presubmit-only'
      pub run test -x presubmit-only || EXIT_CODE=$?
      ;;
    test_13) echo
      echo -e '\033[1mTASK: test_13\033[22m'
      echo -e 'pub run test -t presubmit-only --run-skipped'
      pub run test -t presubmit-only --run-skipped || EXIT_CODE=$?
      ;;
    *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
      EXIT_CODE=1
      ;;
    esac
  done

  popd
done

exit ${EXIT_CODE}
