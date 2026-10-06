# Contributing to this repo

Notes on working in the `build` repo itself. For the CLA and the review
process see [CONTRIBUTING.md](../CONTRIBUTING.md).

-   [Regenerating generated code](#regenerating-generated-code)
-   [Failures that look like flakes](#failures-that-look-like-flakes)

## Regenerating generated code

Several packages in this repo check in generated code: `build_config`,
`build_daemon`, `build_runner`, `builder_pkgs` and the packages under
`built_types`. If you change a type that is used to generate code, you have to
regenerate and check in the result.

The obvious command does not always work:

```sh
dart run build_runner build
```

This builds using the `build` and `build_runner` sources in your working copy.
While you are part way through a change to those packages they may not work,
and then you cannot regenerate the code you need in order to finish the change.

Use the repo's own tool instead:

```sh
# From a package at the top level, for example `build_runner`.
dart ../tool/build_runner_build.dart

# From a package under `built_types`, for example `built_value_test`.
dart ../../tool/build_runner_build.dart
```

It runs the build with published `build` packages from pub, so local breakage
does not matter, but it keeps your local package config, so the generators your
package uses still resolve. Arguments are passed through to
`build_runner build`.

## Failures that look like flakes

The tests in this repo, and especially the integration tests in
`build_runner/test/integration_tests`, write a package to a temporary directory
and then spawn `dart run build_runner` in it. Those subprocesses load `build`
and `build_runner` from your working copy.

So editing anything in the repo while tests are running can break them. A
subprocess may load a file you are part way through saving, or a mix of old and
new sources. The failure appears wherever the test runner happens to be, not
where you made the edit, and it usually reads as a plausible assertion failure
rather than an error about the source. The watch integration tests are the most
frequent victims.

The full `build_runner` suite takes several minutes, which is long enough that
this is easy to do by accident.

So:

-   Do not edit the repo while tests are running. Wait, or run the tests in a
    second checkout.
-   If a test fails in a way you cannot explain, especially a watch test, check
    whether anything changed during the run before you start debugging the
    test.
