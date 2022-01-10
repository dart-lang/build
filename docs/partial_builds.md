# Build Filters

Build filters allow you to choose explicitly which files to build instead of
building entire directories or projects.

A build filter is a combination of a package and a path, with glob syntax
supported for each.

Whenever a build filter is provided, only required outputs matching one of the
build filters will be built, in addition to any required files for those outputs.

## Command Line Usage

Build filters are supplied using the `--build-filter` option, which accepts
relative paths under the root package as well as `package:` uris.

Glob syntax is allowed in both package names and paths.

**Example**: The following would build and serve the JS output for an
application, as well as copy over the required SDK resources for that app:

```
pub run build_runner serve \
  --build-filter="web/main.dart.js" \
  --build-filter="package:build_web_compilers/**/*.js"
```

## Common Use Cases

**Note**: For all the listed use cases it is up to the user or tool the user is
using to request all the required files for the desired task. This package only
provides the core building blocks for these use cases.

### Testing

If you have a large number of tests but only want to run a single one you can
now build just that test instead of all tests under the `test` directory.

This can greatly speed up iteration times in packages with lots of tests.

**Example**: This will build a single web test and run it:

```
pub run build_runner test \
  --build-filter="test/my_test.dart.browser_test.dart.js" \
  --build-filter="package:build_web_compilers/**/*.js" \
  -- -p chrome test/my_test.dart
```

**Note**: If your test requires any other generated files (css, etc) you will
need to add additional filters.

### Applications

This feature works as expected with the `--output <dir>` and the `serve`
command.  This means you can create an output directory for a single
application in your package instead of all applications under the same
directory.

The serve command also uses the build filters to restrict what files are
available, which means it ensures if something works in serve mode it will
also work when you create an output directory.

**Example**: This will build a single web app and serve it:

```
pub run build_runner serve \
  --build-filter="web/my_app.dart.js" \
  --build-filter="package:build_web_compilers/**/*.js"
```

**Note**: Your app may rely on additional code generated files (such as css
files), which you will need to list as additional filters.

### Build Daemon Usage

The build daemon accepts build filters when registering a build target. If no
filters are supplied these default filters are used:

- `<target-dir>/**`
- `package:*/**`
