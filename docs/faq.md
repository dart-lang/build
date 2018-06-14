## How can I debug my release mode web app (dart2js)?

By default, the `dart2js` compiler is only enabled in `--release` mode, which
does not include source maps or the original `.dart` files. If you need to
debug an error which only happens in `dart2js`, you will want to change your
debug mode compiler to `dart2js`. You can either do this using the `--define`
command line option:

```text
--define "build_web_compilers|entrypoint=compiler=dart2js"
```

Or by editing your `build.yaml` file:

```yaml
targets:
  $default:
    builders:
      build_web_compilers|entrypoint:
        options:
          compiler: dart2js
```

## Why do Builders need unique outputs?

`build_runner` relies on determining a static build graph before starting a
build - it needs to know every file that may be written and which Builder would
write it. If multiple Builders are configured to (possibly) output the same file
you can:

- Add a `generate_for` configuration for one or both Builders so they do not
  both operate on the same primary input.
- Disable one of the Builders if it is unneeded.
- Contact the author of the Builder and ask that a more unique output extension
  is chosen.
- Contact the author of the Builder and ask that a more unique input extension
  is chose, for example only generating for files that end in `_something.dart`
  rather than all files that end in `.dart`.
