This package provides support for running builds in a daemon.

Note since `package:build_daemon` is a dependency of `package:build_runner`,
if this is not a clean git checkout you should build this package with the following command:

dart .dart_tool/build/entrypoint/build.dart.snapshot build --skip-build-script-check
