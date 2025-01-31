Benchmarks `build_runner` against synthetic codebases applying real generators:
`built_value`, `freezed`, `json_serializable` or `mockito`.

Example usage:

```
dart run _benchmark \
    --generator=built_value \
    --build-repo-path=$PWD/.. \
    benchmark
```
