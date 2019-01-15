import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:json_serializable/builder.dart';
import 'package:source_gen/builder.dart';

main() async {
  var packageGraph = PackageGraph.forThisPackage();
  var environment = OverrideableEnvironment(IOEnvironment(packageGraph));
  var options = await BuildOptions.create(LogSubscription(environment),
      packageGraph: packageGraph);

  BuildResult result;
  var build = await BuildRunner.create(
    options,
    environment,
    [
      applyToRoot(jsonSerializable(BuilderOptions.forRoot),
          hideOutput: true,
          generateFor: InputSet(include: const [
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
