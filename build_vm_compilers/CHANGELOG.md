## 0.1.1

Individual kernel files are now cleaned up after builds to speed up output
directory creation. This happens in both release and debug modes by default,
and can be disabled in your `build.yaml`:

```yaml
targets:
  $default:
    builders:
      build_vm_compilers|kernel_module_cleanup:
        options:
          enabled: false
```

## 0.1.0

Initial release, adds the modular kernel compiler for the vm platform, and the
entrypoint builder which concatenates all the modules into a single kernel file.
