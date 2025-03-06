#!/bin/bash --

# Runs `dart run build_runner build` using `build` packages from pub instead of
# the local versions. This allows the build to run even when the local versions are
# in a broken state.

# Usage: in one of the `build` repo packages, instead of running
# `dart run build_runner build`, run `../tool/build_runner_build.sh`.

if [[ "$(basename $(dirname "$PWD"))" != "build" ]]; then
  echo "Current directly should be a package inside the build repo."
  exit 1
fi

# Do a pub get to determine the published `build` package versions.
mkdir tmp
cd tmp
cat << EOF > pubspec.yaml
name: none
environment:
  sdk: ^3.7.0
dependencies:
  build_runner: '2.4.15'
EOF
dart pub get >/dev/null 2>&1
cd ..

# Build a version of the current package `package_config.json` with entries
# for`build` packages replaced with the published ones.
cp ../.dart_tool/package_config.json .
for package in \
    build \
    build_config \
    build_daemon \
    build_resolvers \
    build_runner \
    build_runner_core; do
  package_from_pub=$(egrep "\"rootUri\": \".*/$package-.*\"" tmp/.dart_tool/package_config.json)
  sed -i -e "s#      \"rootUri\": \"\\.\\./$package\",#$package_from_pub#" package_config.json
done

# Run the script that `dart run build_runner build` would run, from the pub
# cache and with dependencies from pub. Exit if the build fails so that temporary
# files are left behind.
dart --packages=package_config.json \
    run \
    ~/.pub-cache/hosted/pub.dev/build_runner-2.4.15/bin/build_runner.dart \
    build -d || exit 1

# Clean up.
rm package_config.json
rm tmp/pubspec.yaml
rm tmp/pubspec.lock
rm tmp/.dart_tool/package_config.json
rmdir tmp/.dart_tool
rmdir tmp
