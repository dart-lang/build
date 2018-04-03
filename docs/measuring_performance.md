# Measuring performance with `build` and `build_runner`

You can enable performance tracking by passing the `--track-performance` flag.
To view the result you must be in `serve` mode and navigate to `/$perf`. On that
page you will see a timeline something like this:

![example build](https://photos.app.goo.gl/lk1mHMS64ep0TGTY2)

If you are experiencing slow incremental builds you can save that webpage,
archive the result (zip/tar preferred), and attach it to a github issue for us
to look at.

Note that for larger builds it may take a while to load the timeline.

## Understanding the performance timeline

Each line in the timeline corresponds to a single "action" in the build, which
is a single `Builder` being applied to a single primary input file.

In the left hand column is the name of the builder, followed by a colon, and
then the `AssetId` for the primary input.

The time for each action is split into at 3 primary pieces:

- Setup: Primarily this is time spent checking content hashes of inputs to see
  if the action needs to be reran.
- Build: Time actually spent inside the `build` method of the `Builder`.
- Finalize: Time spent updating the asset graph for all outputs, and some other
  cleanup.

If the builder uses a `Resolver`, you will also see a breakdown of time spent
getting the resolver. This will appear below the `build` time since it overlaps
with it.
