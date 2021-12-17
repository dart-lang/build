#!/bin/bash
# Created with package:mono_repo v6.0.0

# Support built in commands on windows out of the box.
# When it is a flutter repo (check the pubspec.yaml for "sdk: flutter")
# then "flutter" is called instead of "pub".
# This assumes that the Flutter SDK has been installed in a previous step.
function pub() {
  if grep -Fq "sdk: flutter" "${PWD}/pubspec.yaml"; then
    command flutter pub "$@"
  else
    command dart pub "$@"
  fi
}
# When it is a flutter repo (check the pubspec.yaml for "sdk: flutter")
# then "flutter" is called instead of "pub".
# This assumes that the Flutter SDK has been installed in a previous step.
function format() {
  if grep -Fq "sdk: flutter" "${PWD}/pubspec.yaml"; then
    command flutter format "$@"
  else
    command dart format "$@"
  fi
}
# When it is a flutter repo (check the pubspec.yaml for "sdk: flutter")
# then "flutter" is called instead of "pub".
# This assumes that the Flutter SDK has been installed in a previous step.
function analyze() {
  if grep -Fq "sdk: flutter" "${PWD}/pubspec.yaml"; then
    command flutter analyze "$@"
  else
    command dart analyze "$@"
  fi
}

if [[ -z ${PKGS} ]]; then
  echo -e '\033[31mPKGS environment variable must be set! - TERMINATING JOB\033[0m'
  exit 64
fi

if [[ "$#" == "0" ]]; then
  echo -e '\033[31mAt least one task argument must be provided! - TERMINATING JOB\033[0m'
  exit 64
fi

SUCCESS_COUNT=0
declare -a FAILURES

for PKG in ${PKGS}; do
  echo -e "\033[1mPKG: ${PKG}\033[22m"
  EXIT_CODE=0
  pushd "${PKG}" >/dev/null || EXIT_CODE=$?

  if [[ ${EXIT_CODE} -ne 0 ]]; then
    echo -e "\033[31mPKG: '${PKG}' does not exist - TERMINATING JOB\033[0m"
    exit 64
  fi

  dart pub upgrade || EXIT_CODE=$?

  if [[ ${EXIT_CODE} -ne 0 ]]; then
    echo -e "\033[31mPKG: ${PKG}; 'dart pub upgrade' - FAILED  (${EXIT_CODE})\033[0m"
    FAILURES+=("${PKG}; 'dart pub upgrade'")
  else
    for TASK in "$@"; do
      EXIT_CODE=0
      echo
      echo -e "\033[1mPKG: ${PKG}; TASK: ${TASK}\033[22m"
      case ${TASK} in
      analyze_0)
        echo 'dart analyze --fatal-infos .'
        dart analyze --fatal-infos . || EXIT_CODE=$?
        ;;
      analyze_1)
        echo 'dart analyze --fatal-infos'
        dart analyze --fatal-infos || EXIT_CODE=$?
        ;;
      command_0)
        echo 'dart run build_runner test -- -p chrome --test-randomize-ordering-seed=random'
        dart run build_runner test -- -p chrome --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      command_1)
        echo 'dart run build_runner test -- -p vm test/configurable_uri_test.dart --test-randomize-ordering-seed=random'
        dart run build_runner test -- -p vm test/configurable_uri_test.dart --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      command_2)
        echo 'dart run build_runner test -- -p chrome,vm --test-randomize-ordering-seed=random'
        dart run build_runner test -- -p chrome,vm --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      command_3)
        echo 'dart run build_runner test --define="build_web_compilers:entrypoint=compiler=dart2js" -- -p chrome --test-randomize-ordering-seed=random'
        dart run build_runner test --define="build_web_compilers:entrypoint=compiler=dart2js" -- -p chrome --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      format)
        echo 'dart format --output=none --set-exit-if-changed .'
        dart format --output=none --set-exit-if-changed . || EXIT_CODE=$?
        ;;
      test_00)
        echo 'dart test --total-shards 3 --shard-index 0 --test-randomize-ordering-seed=random'
        dart test --total-shards 3 --shard-index 0 --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      test_01)
        echo 'dart test --total-shards 3 --shard-index 1 --test-randomize-ordering-seed=random'
        dart test --total-shards 3 --shard-index 1 --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      test_02)
        echo 'dart test --total-shards 3 --shard-index 2 --test-randomize-ordering-seed=random'
        dart test --total-shards 3 --shard-index 2 --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      test_03)
        echo 'dart test'
        dart test || EXIT_CODE=$?
        ;;
      test_04)
        echo 'dart test --test-randomize-ordering-seed=random'
        dart test --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      test_05)
        echo 'dart test -P presubmit --test-randomize-ordering-seed=random'
        dart test -P presubmit --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      test_06)
        echo 'dart test -x integration --test-randomize-ordering-seed=random'
        dart test -x integration --test-randomize-ordering-seed=random || EXIT_CODE=$?
        ;;
      test_07)
        echo 'dart test -t integration --total-shards 5 --shard-index 0 --test-randomize-ordering-seed=random --no-chain-stack-traces'
        dart test -t integration --total-shards 5 --shard-index 0 --test-randomize-ordering-seed=random --no-chain-stack-traces || EXIT_CODE=$?
        ;;
      test_08)
        echo 'dart test -t integration --total-shards 5 --shard-index 1 --test-randomize-ordering-seed=random --no-chain-stack-traces'
        dart test -t integration --total-shards 5 --shard-index 1 --test-randomize-ordering-seed=random --no-chain-stack-traces || EXIT_CODE=$?
        ;;
      test_09)
        echo 'dart test -t integration --total-shards 5 --shard-index 2 --test-randomize-ordering-seed=random --no-chain-stack-traces'
        dart test -t integration --total-shards 5 --shard-index 2 --test-randomize-ordering-seed=random --no-chain-stack-traces || EXIT_CODE=$?
        ;;
      test_10)
        echo 'dart test -t integration --total-shards 5 --shard-index 3 --test-randomize-ordering-seed=random --no-chain-stack-traces'
        dart test -t integration --total-shards 5 --shard-index 3 --test-randomize-ordering-seed=random --no-chain-stack-traces || EXIT_CODE=$?
        ;;
      test_11)
        echo 'dart test -t integration --total-shards 5 --shard-index 4 --test-randomize-ordering-seed=random --no-chain-stack-traces'
        dart test -t integration --total-shards 5 --shard-index 4 --test-randomize-ordering-seed=random --no-chain-stack-traces || EXIT_CODE=$?
        ;;
      *)
        echo -e "\033[31mUnknown TASK '${TASK}' - TERMINATING JOB\033[0m"
        exit 64
        ;;
      esac

      if [[ ${EXIT_CODE} -ne 0 ]]; then
        echo -e "\033[31mPKG: ${PKG}; TASK: ${TASK} - FAILED (${EXIT_CODE})\033[0m"
        FAILURES+=("${PKG}; TASK: ${TASK}")
      else
        echo -e "\033[32mPKG: ${PKG}; TASK: ${TASK} - SUCCEEDED\033[0m"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      fi

    done
  fi

  echo
  echo -e "\033[32mSUCCESS COUNT: ${SUCCESS_COUNT}\033[0m"

  if [ ${#FAILURES[@]} -ne 0 ]; then
    echo -e "\033[31mFAILURES: ${#FAILURES[@]}\033[0m"
    for i in "${FAILURES[@]}"; do
      echo -e "\033[31m  $i\033[0m"
    done
  fi

  popd >/dev/null || exit 70
  echo
done

if [ ${#FAILURES[@]} -ne 0 ]; then
  exit 1
fi
