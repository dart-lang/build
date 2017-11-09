import 'package:build_runner/build_runner.dart' as _1;
import 'package:provides_builder/builders.dart' as _2;
import 'package:shelf/shelf_io.dart' as _3;

List<_1.BuildAction> _buildActions(_1.PackageGraph packageGraph) {
  var actions = new List<_1.BuildAction>();
  var args = <String>[];
  var buildersForprovides_builder = [_2.someBuilder([])];
  packageGraph.dependentsOf('provides_builder').map((p) => p.name).forEach(
      (p) => actions.addAll(
          buildersForprovides_builder.map((b) => new _1.BuildAction(b, p))));
  return actions;
}

main() async {
  var actions = _buildActions(new _1.PackageGraph.forThisPackage());
  var handler = await _1.watch(actions, writeToCache: true);
  var server = await _3.serve(handler.handlerFor('web'), 'localhost', 8000);
  await handler.buildResults.drain();
  await server.close();
}
