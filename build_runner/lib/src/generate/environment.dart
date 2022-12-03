import 'package:build_runner_core/build_runner_core.dart';
import 'package:logging/logging.dart';

import '../logging/std_io_logging.dart';

BuildEnvironment createEnvironment({
  required PackageGraph packageGraph,
  required bool? assumeTty,
  required bool outputSymlinksOnly,
  required RunnerAssetReader? reader,
  required RunnerAssetWriter? writer,
  required bool? delayAssetWrites,
  required void Function(LogRecord)? onLog,
  required bool verbose,
}) {
  BuildEnvironment environment = IOEnvironment(
    packageGraph,
    assumeTty: assumeTty,
    outputSymlinksOnly: outputSymlinksOnly,
  );
  reader ??= environment.reader;
  writer ??= environment.writer;

  if (delayAssetWrites == true) {
    final delayed = writer = DelayedAssetWriter(writer);
    reader = delayed.reader(reader, packageGraph.root.name);
  }

  environment = environment.change(
    reader: reader,
    writer: writer,
    onLog: onLog ?? stdIOLogListener(assumeTty: assumeTty, verbose: verbose),
  );

  return environment;
}
