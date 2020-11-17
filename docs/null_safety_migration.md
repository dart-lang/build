# Migrating a Builder to support null safety

The null safety feature in Dart presents several challenges for Builder
authors, this is a living document which will address some of the core issues,
as well as potential solutions.

## Language versioning

Language versioning is a new feature introduced to allow an incremental
migration to null safety. It allows an individual package or even library
to set its "language version". This determines what features the library is
able to use.

How this affects your Builder depends on what type of builder you have
implemented, you may choose to only generate null safe code or you may want
to support generating code that is both null safe and not.

## Choosing what type of code to generate

There are a lot of potential factors that determine what options are available
to you, depending on whether you generate part files or new libraries, and
also whether you generate to source or cache.

### Part file builders

Many Builders generate part files, which contain generated code that becomes a
"part" of another library. As a part of the language versioning specification,
these part files _must_ have the same language version as the library that
includes them.

This has two immediate implications for codegen authors:

- If a language version comment exists in the original library, it must be
  copied into all part files included in that library.
  - Note that if you use the `source_gen` package, this is done automatically
    for you, see [this PR](https://github.com/dart-lang/source_gen/pull/472).
- You must generate code compatible with the language version of the library
  that you are generating parts for.

The 2nd point here is the more problematic one, as it requires you to
essentially choose one of the two following solutions:

#### Only support generating null safe code in your new releases

In general, this is the easiest path. You can update your code generator to
only generate null safe code, and throw an `UnsupportedError` if you are asked
to generate code into a library that does not enable null safety.

**Hint**: You can check if null safety is enabled using the
  `isNonNullableByDefault` getter on a `LibraryElement` (in package:analyzer).

If you choose to go this route, you should most likely release this as a
breaking change in your builder package. When people migrate their package to
null safety, they will need to update to the latest version, but existing users
will not be broken.

##### Pros

* Easy to implement, you don't have to support generating multiple versions of
  your code generator that generate null safe or non null safe code.
* Easy to maintain, you don't accumulate tech debt in your Builder just to
  support old language versions, and future changes are easier.

##### Cons

* This requires users to migrate all their libraries with generated parts in
  them to null safety at exactly the same time.
* Users that try to update to the latest version will be broken and have to
  revert back to an old version, if they do not migrate to null safety at the
  same time.

#### Support generating both null safe and non-null safe code

This requires some extra work but is the least friction for your users. You can
get clever about exactly how this is done, without having to fork two
completely separate versions of your Builder code, and as more people do this
we expect some common patterns to emerge (please send prs here to add your
creative solutions!).

##### Use variables for null syntax strings that are empty if disabled

For instance, when writing out a nullable type `int?`, you can instead do
something like this `int$maybeQuestionMark`, where `$maybeQuestionMark` is
either assigned to the string `'?'` or is empty, depending on if null safety is
enabled.

##### Pros

* Works for all users regardless of their language version.

##### Cons

* More work to implement and maintain.

### Library builders

If your builder generates completely new libraries, then you have either one or
two extra potential options available to you, depending on if you generate to
cache or source.

**Note**: All the options available to part builders are also available to
library builders.

#### Forcibly opt your generated library in to null safety

**Note**: This option is only generally available to builders that build to
_cache_. This is because the pub package manager does not allow the publishing
of code that specifies a language version greater than the min sdk constraint
of the package (and the min sdk constraint is what determines the default
language version). So, your users would not be able to publish your generated
code.

You can opt your generated library into null safety by adding a language
version override comment to comment block at the top of the file (it can appear
after the license):

```dart
// @dart=<version>
```

(At the time of this writing, the final language version for null safety has
not yet been determined, so one is not listed in the example)

This allows you to only generate null safe code that works for all users.

**Note**: This approach does also mean your generator should set _its_ min sdk
constraint to whatever version it will override the language to. That ensures
that your users only get this version of the generator if their sdk supports
that version of the language.

##### Pros

* Easier to implement, you only have to generate null safe code.

##### Cons

* You can only safely do this for builders that build to cache, not source.

## Testing

### Language versioning

The `build_test` package apis accept an optional `packageConfig` parameter,
which can be used to set a specific language version for packages. This can be
used to test generating code for packages that are opted in or out to null
safety.

You can see an example of using this in [this test][PackageConfig test]. Note
that the `rootUri` and `packageUriRoot` arguments for packages are largely
irrelevant during testing, although they do need to be unique.

### Enabling experiments

Null safety at the time of this writing is still an experiment, but you can
still write tests today, using the `withEnabledExperiments` api from the
`package:build/experiments.dart` library.

See [this test][withEnabledExperiments test] as an example of how to use it.

**Note**: For language experiments the language version required to enable it
is typically the **current** language version, so you may need to update your
tests for new sdk versions to increase their language version and opt them
back in.

[PackageConfig test]: https://github.com/dart-lang/build/blob/4c76bbfbdbf7e905ab155ad95299b4b306f8b529/build_test/test/test_builder_test.dart#L160
[withEnabledExperiments test]: https://github.com/dart-lang/build/blob/4c76bbfbdbf7e905ab155ad95299b4b306f8b529/build_resolvers/test/resolver_test.dart#L362
