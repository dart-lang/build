## Configuring native null assertions

You can configure the native null assertions behavior in your `build.yaml` file
using the `native_null_assertions` option on the
`build_web_compilers:entrypoint` builder.

For a typical package that would look like this:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        options:
          native_null_assertions: true
```

You can also configure this using the command line by adding the following
argument to your build_runner command:

`--define=build_web_compilers:entrypoint=native_null_assertions=true`
