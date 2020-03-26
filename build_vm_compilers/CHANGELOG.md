## 1.0.5-dev

- Increase min sdk constraint to `>=2.7.0`.

## 1.0.4

- Allow analyzer version `0.39.0`.

## 1.0.3

- Allow analyzer version `0.38.0`.

## 1.0.2

- Fix kernel concat ordering to be topological instead of reverse
  topological.

## 1.0.1

- Allow analyzer version 0.37.0.

## 1.0.0

- Support build_modules 2.0.0
  - Define our own `vm` platform and builders explicitly.
- Skip trying to compile apps that import known incompatible libraries.

## 0.1.2

- Increased the upper bound for `package:analyzer` to `<0.37.0`.
- Require Dart SDK `>=2.1.0`.

## 0.1.1+5

- Increased the upper bound for `package:analyzer` to `<0.36.0`.

## 0.1.1+4

- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 0.1.1+3

- Increased the upper bound for `package:analyzer` to `<0.34.0`.

## 0.1.1+2

Support `package:build_modules` version `1.x.x`.

## 0.1.1+1

Support `package:build` version `1.x.x`.

## 0.1.1

Support the latest build_modules.

## 0.1.0

Initial release, adds the modular kernel compiler for the vm platform, and the
entrypoint builder which concatenates all the modules into a single kernel file.
