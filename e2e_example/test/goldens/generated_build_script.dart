import 'package:build_runner/build_runner.dart' as _1;
import 'package:provides_builder/builders.dart' as _2;
import 'package:build_compilers/builders.dart' as _3;
import 'package:shelf/shelf_io.dart' as _4;

List<_1.BuildAction> _buildActions(_1.PackageGraph packageGraph) {
  var args = <String>[];
  var builders = [
    _1.apply('provides_builder', 'some_builder', [_2.someBuilder],
        _1.toDependentsOf('provides_builder')),
    _1.apply(
        'build_compilers',
        'ddc',
        [
          _3.moduleBuilder,
          _3.unlinkedSummaryBuilder,
          _3.linkedSummaryBuilder,
          _3.devCompilerBuilder
        ],
        _1.toAllPackages(),
        isOptional: true),
    _1.apply('build_compilers', 'ddc_bootstrap',
        [_3.devCompilerBootstrapBuilder], _1.toPackage('e2e_example'),
        inputs: ['web/**.dart', 'test/**.browser_test.dart'])
  ];
  return _1.createBuildActions(packageGraph, builders, args: args);
}

main() async {
  var actions = _buildActions(new _1.PackageGraph.forThisPackage());
  var handler = await _1.watch(actions, writeToCache: true);
  var server = await _4.serve(handler.handlerFor('web'), 'localhost', 8000);
  await handler.buildResults.drain();
  await server.close();
}
