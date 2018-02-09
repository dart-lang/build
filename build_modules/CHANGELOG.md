# 0.1.0+2

- Fix a bug with the dart2js workers where the worker could hang if you try to
  re-use it after calling `terminateWorkers`. This only really surfaces in test
  environments.

# 0.1.0+1

- Fix a bug with imports to libraries that have names starting with `dart.`

# 0.1.0

- Split from `build_web_compilers`.
