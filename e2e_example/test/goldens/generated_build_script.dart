import 'package:build_runner/build_runner.dart' as _i1;
import 'package:provides_builder/builders.dart' as _i2;
import 'package:build_compilers/builders.dart' as _i3;

final _builders = [
  _i1.apply('provides_builder', 'some_not_applied_builder', [_i2.notApplied],
      _i1.toNoneByDefault()),
  _i1.apply('provides_builder', 'some_builder', [_i2.someBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true),
  _i1.apply(
      'build_compilers',
      'ddc',
      [
        _i3.moduleBuilder,
        _i3.unlinkedSummaryBuilder,
        _i3.linkedSummaryBuilder,
        _i3.devCompilerBuilder
      ],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true),
  _i1.apply('build_compilers', 'ddc_bootstrap',
      [_i3.devCompilerBootstrapBuilder], _i1.toNoneByDefault(),
      hideOutput: true),
  _i1.apply('build_compilers', 'ddc_bootstrap',
      [_i3.devCompilerBootstrapBuilder], _i1.toRoot(),
      inputs: ['web/**.dart', 'test/**.browser_test.dart'], hideOutput: true)
];
main(List<String> args) => _i1.run(args, _builders);
