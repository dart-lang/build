# Measuring performance with `build` and `build_runner`

You can enable performance tracking by passing the `--log-performance <dir>`
option (which will save logs to disk) or the `--track-performance` flag. Both
of these options will allow you to view the result in `serve` mode by
navigating to `/$perf`. On that page you will see a timeline something like this:

![example build](/docs/images/example_build.png)

If you are using the `--log-performance <dir>` option that will save the logs
to disk so that you can attach them to bug reports.

Note that for larger builds it may take a while to load the timeline.

## Understanding the performance timeline

Each line in the timeline corresponds to a single "action" in the build, which
is a single `Builder` being applied to a single primary input file.

In the left hand column is the name of the builder, followed by a colon, and
then the `AssetId` for the primary input.

The time for each action is split into at 3 primary pieces:

- **Setup**: Primarily this is time spent checking content hashes of inputs to see
  if the action needs to be reran.
  - __Note__: This may also involve lazily building assets that were optional,
    so seeing a long time here is not unexpected.
- **Build**: Time actually spent inside the `build` method of the `Builder`.
- **Finalize**: Time spent updating the asset graph for all outputs, and some other
  cleanup.

If the builder uses a `Resolver`, you will also see a breakdown of time spent
getting the resolver. This will appear below the `build` time since it overlaps
with it.
