import 'dart:io';

import 'package:build_runner/src/contracts/transform.dart';

Future<void> main(List<String> args) async {
  final clean = args.contains('--clean');
  final filteredArgs = args
      .where((a) => a != '--clean' && !a.startsWith('--stage-dir='))
      .toList();

  final stageDirArg = args
      .where((a) => a.startsWith('--stage-dir='))
      .map((a) => a.substring('--stage-dir='.length))
      .firstOrNull;

  final stageDir = Directory(
    stageDirArg ?? '${Directory.systemTemp.path}/contracts_workspace',
  );

  // Locate the root workspace directory containing workspace pubspec.yaml.
  Directory? workspaceRoot;
  for (var dir = Directory.current; ; dir = dir.parent) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (content.contains('workspace:')) {
        workspaceRoot = dir;
        break;
      }
    }
    if (dir.path == dir.parent.path) break;
  }

  if (workspaceRoot == null) {
    stderr.writeln('Error: Could not locate workspace root pubspec.yaml.');
    exitCode = 1;
    return;
  }

  if (clean && stageDir.existsSync()) {
    stdout.writeln('Cleaning staged workspace at ${stageDir.path} ...');
    stageDir.deleteSync(recursive: true);
  }

  stdout.writeln('Staging contracts workspace at ${stageDir.path} ...');
  stageDir.createSync(recursive: true);

  // Copy root workspace configuration files.
  for (final filename in [
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'dart_test.yaml',
  ]) {
    final src = File('${workspaceRoot.path}/$filename');
    if (src.existsSync()) {
      final dest = File('${stageDir.path}/$filename');
      dest.writeAsStringSync(src.readAsStringSync());
    }
  }

  // Symlink top-level packages and directories from workspace root.
  for (final entity in workspaceRoot.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name.startsWith('.') ||
        name == 'build_runner' ||
        name == 'pubspec.yaml' ||
        name == 'pubspec.lock' ||
        name == 'analysis_options.yaml' ||
        name == 'dart_test.yaml') {
      continue;
    }
    final link = Link('${stageDir.path}/$name');
    final type = FileSystemEntity.typeSync(link.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      link.createSync(entity.absolute.path);
    }
  }

  // Setup build_runner in staged workspace.
  final srcBuildRunner = Directory('${workspaceRoot.path}/build_runner');
  final stagedBuildRunner = Directory('${stageDir.path}/build_runner');
  stagedBuildRunner.createSync(recursive: true);

  for (final entity in srcBuildRunner.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name.startsWith('.') || name == 'lib') continue;

    final targetPath = '${stagedBuildRunner.path}/$name';
    final type = FileSystemEntity.typeSync(targetPath, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      Link(targetPath).createSync(entity.absolute.path);
    }
  }

  // Populate staged build_runner/lib with transformed contracts.
  final srcLib = Directory('${srcBuildRunner.path}/lib');
  final stagedLib = Directory('${stagedBuildRunner.path}/lib');
  stagedLib.createSync(recursive: true);

  var transformedCount = 0;
  var symlinkCount = 0;

  for (final entity in srcLib.listSync(recursive: true)) {
    final relative = entity.path.substring(srcLib.path.length + 1);
    final targetPath = '${stagedLib.path}/$relative';

    if (entity is Directory) {
      Directory(targetPath).createSync(recursive: true);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final transformed = transformContracts(content);

      // Clean up previous entity at target if type differs.
      final existingType = FileSystemEntity.typeSync(
        targetPath,
        followLinks: false,
      );

      if (transformed != content) {
        if (existingType == FileSystemEntityType.link) {
          Link(targetPath).deleteSync();
        }
        File(targetPath).writeAsStringSync(transformed);
        transformedCount++;
      } else {
        if (existingType == FileSystemEntityType.file) {
          File(targetPath).deleteSync();
        }
        if (existingType == FileSystemEntityType.notFound) {
          Link(targetPath).createSync(entity.absolute.path);
        }
        symlinkCount++;
      }
    }
  }

  stdout.writeln(
    'Staged build_runner/lib: $transformedCount transformed, '
    '$symlinkCount symlinked.',
  );

  // Ensure dependencies are resolved in staged workspace.
  final stagedPackageConfig = File(
    '${stageDir.path}/.dart_tool/package_config.json',
  );
  if (!stagedPackageConfig.existsSync()) {
    stdout.writeln('Resolving dependencies in staged workspace...');
    final pubResult = await Process.run(Platform.resolvedExecutable, [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: stageDir.path);
    if (pubResult.exitCode != 0) {
      // Fall back to online pub get if offline cache does not suffice.
      await Process.run(Platform.resolvedExecutable, [
        'pub',
        'get',
      ], workingDirectory: stageDir.path);
    }
  }

  stdout.writeln('Running tests with contracts enabled...');
  final testProcess = await Process.start(
    Platform.resolvedExecutable,
    ['test', ...filteredArgs],
    workingDirectory: stagedBuildRunner.path,
    environment: {...Platform.environment, 'DART_CONTRACTS_ENABLED': 'true'},
    mode: ProcessStartMode.inheritStdio,
  );

  exitCode = await testProcess.exitCode;
}
