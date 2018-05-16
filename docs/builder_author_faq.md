## When should a Builder build to `cache` vs `source`?

Use `build_to: source` when:
- The generated code _does not_ depend on details outside of the containing
  package that might change with a different version of it's dependencies. Any
  details from the _generating_ package, or any other dependency used by the
  generated code must not change without a major version bump.
- The generated code should be `pub publish`ed with the package and used by
  downstream packages without running a build themselves.

Use `build_to: cache` when:
- The generated code uses details from outside of the package with the generated
  code, including from the _generating_ package which may change without a major
  version bump.
- The builder generates lots of files that the user might not expect to see.
- The builder targets use cases for "application" packages that are unlikely to
  be published rather than packages which will be published and become
  dependencies.
