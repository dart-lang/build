import 'dart:convert';
import 'dart:io';

import 'package:build_runner/src/contracts/transform.dart';

Future<void> main(List<String> args) async {
  final buildRunnerDir = Directory.current;
  final libDir = Directory('${buildRunnerDir.path}/lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Error: lib/ directory not found in current directory.');
    exitCode = 1;
    return;
  }

  final outContractsDir = Directory(
    '${buildRunnerDir.path}/.dart_tool/contracts',
  );
  final outLibDir = Directory('${outContractsDir.path}/lib');

  if (outLibDir.existsSync()) {
    outLibDir.deleteSync(recursive: true);
  }
  outLibDir.createSync(recursive: true);

  var transformedCount = 0;
  var copiedCount = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relative = entity.path.substring(libDir.path.length + 1);
      final outFile = File('${outLibDir.path}/$relative');
      outFile.parent.createSync(recursive: true);

      final content = entity.readAsStringSync();
      final transformed = transformContracts(content);
      if (transformed != content) {
        outFile.writeAsStringSync(transformed);
        transformedCount++;
      } else {
        outFile.writeAsStringSync(content);
        copiedCount++;
      }
    }
  }

  stdout.writeln(
    'Transformed $transformedCount files to ${outLibDir.path} '
    '($copiedCount unchanged).',
  );

  // Locate the root package_config.json.
  File? rootPackageConfig;
  for (var dir = buildRunnerDir; ; dir = dir.parent) {
    final candidate = File('${dir.path}/.dart_tool/package_config.json');
    if (candidate.existsSync()) {
      rootPackageConfig = candidate;
      break;
    }
    if (dir.path == dir.parent.path) break;
  }

  if (rootPackageConfig == null) {
    stderr.writeln(
      'Error: Could not locate root .dart_tool/package_config.json',
    );
    exitCode = 1;
    return;
  }

  final rootWorkspaceDir = rootPackageConfig.parent.parent.path;
  final configData =
      jsonDecode(rootPackageConfig.readAsStringSync()) as Map<String, dynamic>;
  final packages = (configData['packages'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  for (final p in packages) {
    final uri = p['rootUri'] as String;
    if (uri.startsWith('../')) {
      p['rootUri'] = 'file://$rootWorkspaceDir/${uri.substring(3)}';
    }
    if (p['name'] == 'build_runner') {
      p['packageUri'] = '.dart_tool/contracts/lib/';
    }
  }

  final outConfigFile = File('${outContractsDir.path}/package_config.json');
  outConfigFile.writeAsStringSync(jsonEncode(configData));

  if (args.contains('--transform-only')) {
    stdout.writeln('Transform complete.');
    return;
  }

  stdout.writeln('Running tests with contracts enabled...');
  final testProcess = await Process.start(
    Platform.resolvedExecutable,
    ['run', '--packages=${outConfigFile.path}', 'test:test', ...args],
    environment: {...Platform.environment, 'DART_CONTRACTS_ENABLED': 'true'},
    mode: ProcessStartMode.inheritStdio,
  );

  exitCode = await testProcess.exitCode;
}
