#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ "$#" == "0" ]; then
  echo -e '\033[31mAt least one task argument must be provided!\033[0m'
  exit 1
fi

pushd $PKG
pub upgrade

while (( "$#" )); do
  TASK=$1
  case $TASK in
  command) echo
    echo -e '\033[1mTASK: command\033[22m'
    echo -e 'pub run build_runner test -- -p chrome'
    pub run build_runner test -- -p chrome
    ;;
  dartanalyzer) echo
    echo -e '\033[1mTASK: dartanalyzer\033[22m'
    echo -e 'dartanalyzer --fatal-infos --fatal-warnings .'
    dartanalyzer --fatal-infos --fatal-warnings .
    ;;
  dartfmt) echo
    echo -e '\033[1mTASK: dartfmt\033[22m'
    echo -e 'dartfmt -n --set-exit-if-changed .'
    dartfmt -n --set-exit-if-changed .
    ;;
  test_0) echo
    echo -e '\033[1mTASK: test_0\033[22m'
    echo -e 'pub run test'
    pub run test
    ;;
  test_1) echo
    echo -e '\033[1mTASK: test_1\033[22m'
    echo -e 'pub run test --run-skipped'
    pub run test --run-skipped
    ;;
  test_2) echo
    echo -e '\033[1mTASK: test_2\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 0'
    pub run test --total-shards 4 --shard-index 0
    ;;
  test_3) echo
    echo -e '\033[1mTASK: test_3\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 1'
    pub run test --total-shards 4 --shard-index 1
    ;;
  test_4) echo
    echo -e '\033[1mTASK: test_4\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 2'
    pub run test --total-shards 4 --shard-index 2
    ;;
  test_5) echo
    echo -e '\033[1mTASK: test_5\033[22m'
    echo -e 'pub run test --total-shards 4 --shard-index 3'
    pub run test --total-shards 4 --shard-index 3
    ;;
  *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    exit 1
    ;;
  esac

  shift
done
