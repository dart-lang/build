#!/bin/bash
# Created with https://github.com/dart-lang/mono_repo

# Fast fail the script on failures.
set -e

# Custom hand-written code - this needs to be added back in after mono_repo
# commands.
if [ ! -z "$TRAVIS_OS_NAME" ]; then
  if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    echo "starting xvfb"
    export DISPLAY=:99.0
    sh -e /etc/init.d/xvfb start
    t=0
    until (xdpyinfo -display :99 &> /dev/null || test $t -gt 10);
      do sleep 1
      let t=$t+1
    done
  fi
fi
# End custom code

if [ -z "$PKG" ]; then
  echo -e "PKG environment variable must be set!"
  exit 1
elif [ -z "$TASK" ]; then
  echo -e "TASK environment variable must be set!"
  exit 1
fi

pushd $PKG
pub upgrade

case $TASK in
dartanalyzer) echo
  echo -e "TASK: dartanalyzer"
  dartanalyzer --fatal-infos --fatal-warnings .
  ;;
dartfmt) echo
  echo -e "TASK: dartfmt"
  dartfmt -n --set-exit-if-changed .
  ;;
test) echo
  echo -e "TASK: test"
  pub run test
  ;;
test_1) echo
  echo -e "TASK: test_1"
  pub run test --run-skipped
  ;;
*) echo -e "Not expecting TASK '${TASK}'. Error!"
  exit 1
  ;;
esac
