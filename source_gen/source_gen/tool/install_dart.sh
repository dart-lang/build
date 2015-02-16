#!/bin/bash

set -e -x

DART_CHANNEL=$1
ARCH=$2

AVAILABLE_DART_VERSION=$(curl "https://storage.googleapis.com/dart-archive/channels/${DART_CHANNEL}/release/latest/VERSION" | python -c \
    'import sys, json; print(json.loads(sys.stdin.read())["version"])')

echo Fetch Dart channel: ${DART_CHANNEL}

URL_PREFIX=https://storage.googleapis.com/dart-archive/channels/${DART_CHANNEL}/release/latest
DART_SDK_URL="$URL_PREFIX/sdk/dartsdk-$ARCH-release.zip"

download_and_unzip() {
  ZIPFILE=${1/*\//}
  curl -O -L $1 && unzip -q $ZIPFILE && rm $ZIPFILE
}

# TODO: do these downloads in parallel
download_and_unzip $DART_SDK_URL

echo Fetched new dart version $(<dart-sdk/version)
