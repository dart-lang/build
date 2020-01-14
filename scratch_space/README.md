[![Build Status](https://travis-ci.org/dart-lang/build.svg?branch=master)](https://travis-ci.org/dart-lang/build)
[![Pub Package](https://img.shields.io/pub/v/scratch_space.svg)](https://pub.dev/packages/scratch_space)

A [`ScratchSpace`][dartdoc:ScratchSpace] is a thin wrapper around a temporary
directory. The constructor takes zero arguments, so making one is as simple as
doing `ScratchSpace()`.

In general, you should wrap a `ScratchSpace` in a `Resource`, so that you can
re-use the scratch space across build steps in an individual build. This is
safe to do since you are not allowed to overwrite files within a build.

This should look something like the following:

```
final myScratchSpaceResource =
    Resource(() => ScratchSpace(), dispose: (old) => old.delete());
```

And then you can get access to it through the `BuildStep#fetchResource` api:

```
class MyBuilder extends Builder {
  Future<void> build(BuildStep buildStep) async {
    var scratchSpace = await buildStep.fetchResource(myScratchSpaceResource);
  }
}
```

### Adding assets to a `ScratchSpace`

To add assets to the `ScratchSpace`, you use the `ensureAssets` method, which
takes an `Iterable<AssetId>` and an `AssetReader` (for which you should
generally pass your `BuildStep` which implements that interface).

You must always call this method with all assets that your external executable
might need in order to set up the proper dependencies and ensure hermetic
builds.

**Note:** It is important to note that the `ScratchSpace` does not guarantee
that the version of a file within it is the most updated version, only that
some version of it exists. For this reason you should create a new
`ScratchSpace` for each build using the `Resource` class as recommended above.

### Deleting a `ScratchSpace`

When you are done with a `ScratchSpace` you should call `delete` on it to make
sure it gets cleaned up, otherwise you can end up filling up the users tmp
directory.

**Note:** You cannot delete individual assets from a `ScratchSpace` today, you
can only delete the entire thing. If you have a use case for deleting
individual files you can [file an issue][tracker].

### Getting the actual File objects for a `ScratchSpace`

When invoking an external binary, you probably need to tell it where to look
for files. There are a few fields/methods to help you do this:

  * `String get packagesDir`: The `packages` directory in the `ScratchSpace`.
  * `String get tmpDir`: The root temp directory for the `ScratchSpace`.
  * `File fileFor(AssetId id)`: The File object for `id`.

### Copying back outputs from the temp directory

After running your executable, you most likely have some outputs that you
need to notify the build system about. To do this you can use the `copyOutput`
method, which takes an `AssetId` and `AssetWriter` (for which you should
generally pass your `BuildStep` which implements that interface).

This will copy the asset referenced by the `AssetId` from the temp directory
back to your actual output directory.

## Feature requests and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/build/issues
[dartdoc:ScratchSpace]: https://pub.dev/documentation/scratch_space/latest/scratch_space/ScratchSpace-class.html
