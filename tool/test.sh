#!/bin/bash

# Fast fail the script on failures.
set -e

if [ -z "$PKG" ]; then
  echo -e '\033[31mPKG environment variable must be set!\033[0m'
  exit 1
fi

pushd $PKG
pub upgrade
pub run build_runner test -- -p chrome
