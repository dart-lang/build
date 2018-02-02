#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

if [ "$#" == "0" ]; then
  echo -e "\033[31mExpected at least one task!\033[0m"
  exit 1
fi
EXIT_CODE=0

pushd $PKG
pub upgrade || EXIT_CODE=$?

while (( "$#" )); do
  TASK=$1

  case $TASK in
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
    echo -e 'pub run test'
    pub run test || EXIT_CODE=$?
    ;;
  test_1) echo
    echo -e '\033[1mTASK: test_1\033[22m'
    echo -e 'pub run test --run-skipped'
    pub run test --run-skipped || EXIT_CODE=$?
    ;;
  *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
    EXIT_CODE=$?
    ;;
  esac

  shift
done

exit $EXIT_CODE
