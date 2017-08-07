import 'package:build_runner/build_runner.dart';
import 'package:e2e_example/copy_builder.dart';

final phases = [
  new BuildAction(new CopyBuilder(),
      new PackageGraph.forThisPackage().root.name, ['**/*.txt'])
];
