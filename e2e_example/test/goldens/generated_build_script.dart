import 'package:build_runner/build_runner.dart' as _1;
import 'package:provides_builder/builders.dart' as _2;
import 'package:shelf/shelf_io.dart' as _3;

List<_1.BuildAction> _buildActions(_1.PackageGraph packageGraph) {
  var args = <String>[];
  var builders = [
    _1.apply(_2.someBuilder(args), _1.toDependentsOf('provides_builder'))
  ];
  return _1.createBuildActions(packageGraph, builders);
}

main() async {
  var actions = _buildActions(new _1.PackageGraph.forThisPackage());
  var handler = await _1.watch(actions, writeToCache: true);
  var server = await _3.serve(handler.handlerFor('web'), 'localhost', 8000);
  await handler.buildResults.drain();
  await server.close();
}
