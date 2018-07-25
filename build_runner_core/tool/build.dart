import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:json_serializable/builder.dart';
import 'package:source_gen/builder.dart';

main() async {
  var packageGraph = new PackageGraph.forThisPackage();
  var environment =
      new OverrideableEnvironment(new IOEnvironment(packageGraph));
  var options =
      await BuildOptions.create(environment, packageGraph: packageGraph);

  BuildResult result;
  var build = await BuildRunner.create(
    options,
    environment,
    [
      applyToRoot(jsonSerializable(BuilderOptions.forRoot),
          hideOutput: true,
          generateFor: new InputSet(include: const [
            'lib/src/generate/performance_tracker.dart',
          ])),
      applyToRoot(combiningBuilder())
    ],
    const {},
  );
  result = await build.run({});
  if (result.status != BuildStatus.success) {
    print('Build Failed!:\n$result');
  }
  await build.beforeExit();
}
