Benchmarks `build_runner` against synthetic codebases applying real generators:
`built_value`, `freezed`, `json_serializable` or `mockito`.

Example usage:

```
# Benchmark `build_runner` from pub.
dart run _benchmark \
    --generator=built_value \
    benchmark

# Benchmark a local version of `build_runner`.
dart run _benchmark \
    --generator=built_value \
    --build-repo-path=$PWD/.. \
    benchmark
```
