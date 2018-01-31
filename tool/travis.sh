#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e "\033[31mPKG environment variable must be set!\033[0m"
  exit 1
elif [ -z "$TASK" ]; then
  echo -e "\033[31mTASK environment variable must be set!\033[0m"
  exit 1
fi

pushd $PKG
pub upgrade

case $TASK in
dartanalyzer) echo
  echo -e "\033[1mTASK: dartanalyzer\033[22m"
  dartanalyzer --fatal-infos --fatal-warnings .
  ;;
dartfmt) echo
  echo -e "\033[1mTASK: dartfmt\033[22m"
  dartfmt -n --set-exit-if-changed .
  ;;
test) echo
  echo -e "\033[1mTASK: test\033[22m"
  pub run test
  ;;
test_1) echo
  echo -e "\033[1mTASK: test_1\033[22m"
  pub run test --run-skipped
  ;;
*) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
  exit 1
  ;;
esac
