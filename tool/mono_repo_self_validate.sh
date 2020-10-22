#!/bin/bash
# Created with package:mono_repo v3.0.0-dev

# Support built in commands on windows out of the box.
function pub() {
  if [[ $TRAVIS_OS_NAME == "windows" ]]; then
    command pub.bat "$@"
  else
    command pub "$@"
  fi
}

set -v -e
pub global activate mono_repo 3.0.0-dev
pub global run mono_repo travis --validate
