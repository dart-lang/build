#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ "$#" == "0" ]; then
  echo -e '\033[31mAt least one task argument must be provided!\033[0m'
  exit 1
fi

export DART_VM_OPTIONS=--preview-dart-2

pushd $PKG
pub upgrade || exit $?

EXIT_CODE=0

while (( "$#" )); do
  TASK=$1
  case $TASK in
  command) echo
    echo -e '\033[1mTASK: command\033[22m'
    echo -e 'pub run build_runner test -- -p chrome'
    pub run build_runner test -- -p chrome || EXIT_CODE=$?
    ;;
  dartanalyzer) echo
    echo -e '\033[1mTASK: dartanalyzer\033[22m'
    echo -e 'dartanalyzer --fatal-infos --fatal-warnings .'
    dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?
    ;;
  dartfmt) echo
    echo -e '\033[1mTASK: dartfmt\033[22m'
    echo -e 'dartfmt -n --set-exit-if-changed .'
    dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
    ;;
  test_0) echo
    echo -e '\033[1mTASK: test_0\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 0'
    pub run test --total-shards 4 --shard-index 0 || EXIT_CODE=$?
    ;;
  test_1) echo
    echo -e '\033[1mTASK: test_1\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 1'
    pub run test --total-shards 4 --shard-index 1 || EXIT_CODE=$?
    ;;
  test_2) echo
    echo -e '\033[1mTASK: test_2\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 2'
    pub run test --total-shards 4 --shard-index 2 || EXIT_CODE=$?
    ;;
  test_3) echo
    echo -e '\033[1mTASK: test_3\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 3'
    pub run test --total-shards 4 --shard-index 3 || EXIT_CODE=$?
    ;;
  test_4) echo
    echo -e '\033[1mTASK: test_4\033[22m'
    echo -e 'pub run test'
    pub run test || EXIT_CODE=$?
    ;;
  test_5) echo
    echo -e '\033[1mTASK: test_5\033[22m'
    echo -e 'pub run test -x integration'
    pub run test -x integration || EXIT_CODE=$?
    ;;
  test_6) echo
    echo -e '\033[1mTASK: test_6\033[22m'
    echo -e 'pub run test -t integration'
    pub run test -t integration || EXIT_CODE=$?
    ;;
  test_7) echo
    echo -e '\033[1mTASK: test_7\033[22m'
    echo -e 'pub run test -x presubmit-only'
    pub run test -x presubmit-only || EXIT_CODE=$?
    ;;
  test_8) echo
    echo -e '\033[1mTASK: test_8\033[22m'
    echo -e 'pub run test -t presubmit-only --run-skipped'
    pub run test -t presubmit-only --run-skipped || EXIT_CODE=$?
    ;;
  *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    EXIT_CODE=1
    ;;
  esac

  shift
done

exit $EXIT_CODE
