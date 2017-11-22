import 'package:build_runner/build_runner.dart' as _i1;
import 'package:provides_builder/builders.dart' as _i2;
import 'package:build_compilers/builders.dart' as _i3;
import 'package:shelf/shelf_io.dart' as _i4;

List<_i1.BuildAction> _buildActions(_i1.PackageGraph packageGraph) {
  var args = <String>[];
  var builders = [
    _i1.apply('provides_builder', 'some_builder', [_i2.someBuilder],
        _i1.toDependentsOf('provides_builder')),
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
        isOptional: true),
    _i1.apply('build_compilers', 'ddc_bootstrap',
        [_i3.devCompilerBootstrapBuilder], _i1.toPackage('e2e_example'),
        inputs: ['web/**.dart', 'test/**.browser_test.dart'])
  ];
  return _i1.createBuildActions(packageGraph, builders, args: args);
}

main() async {
  var actions = _buildActions(new _i1.PackageGraph.forThisPackage());
  var handler = await _i1.watch(actions, writeToCache: true);
  var server = await _i4.serve(handler.handlerFor('web'), 'localhost', 8000);
  await handler.buildResults.drain();
  await server.close();
}
