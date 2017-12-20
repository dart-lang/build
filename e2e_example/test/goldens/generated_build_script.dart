import 'package:build_runner/build_runner.dart' as _i1;
import 'package:provides_builder/builders.dart' as _i2;
import 'package:build_test/builder.dart' as _i3;
import 'package:build_config/build_config.dart' as _i4;
import 'package:build_compilers/builders.dart' as _i5;

final _builders = [
  _i1.apply('provides_builder|some_not_applied_builder', [_i2.notApplied],
      _i1.toNoneByDefault()),
  _i1.apply('provides_builder|some_builder', [_i2.someBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true),
  _i1.apply(
      'build_test|test_bootstrap', [_i3.testBootstrapBuilder], _i1.toRoot(),
      isOptional: true,
      hideOutput: true,
      defaultGenerateFor: const _i4.InputSet(include: const ['test/**'])),
  _i1.apply(
      'build_compilers|ddc',
      [
        _i5.moduleBuilder,
        _i5.unlinkedSummaryBuilder,
        _i5.linkedSummaryBuilder,
        _i5.devCompilerBuilder
      ],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true),
  _i1.apply('build_compilers|ddc_bootstrap', [_i5.devCompilerBootstrapBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i4.InputSet(
          include: const ['web/**', 'test/**.browser_test.dart']))
];
main(List<String> args) => _i1.run(args, _builders);
