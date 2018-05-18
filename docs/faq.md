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
