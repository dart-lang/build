import 'package:build_runner/build_runner.dart';
import 'package:e2e_example/copy_builder.dart';

final phases = new PhaseGroup()
  ..newPhase().addAction(new CopyBuilder(),
      new InputSet(new PackageGraph.forThisPackage().root.name, ['**/*.txt']));
