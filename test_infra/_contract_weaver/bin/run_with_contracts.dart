import 'dart:convert';
import 'dart:io';

import 'package:_contract_weaver/contract_weaver.dart';

const _usage = '''
Usage: run_with_contracts --package=NAME [options] [test args]

  --package=NAME          Package in the workspace to weave contracts into.
  --stage-dir=PATH        Where to build the woven copy.
  --clean                 Delete the stage directory first.
  --analyze-only          Analyze the woven copy and skip the tests.
  --contract-import=M1,M2=URI
                          Import URI into woven sources mentioning any marker.
                          Repeatable.
''';

Future<void> main(List<String> args) async {
  final clean = args.contains('--clean');
  final analyzeOnly = args.contains('--analyze-only');

  String? valueOf(String flag) => args
      .where((a) => a.startsWith('$flag='))
      .map((a) => a.substring(flag.length + 1))
      .firstOrNull;

  final package = valueOf('--package');
  if (package == null) {
    stderr.writeln(_usage);
    exitCode = 1;
    return;
  }

  final importRules = <ContractImportRule>[];
  for (final arg in args.where((a) => a.startsWith('--contract-import='))) {
    final spec = arg.substring('--contract-import='.length);
    final split = spec.lastIndexOf('=');
    if (split == -1) {
      stderr.writeln('Malformed --contract-import, expected MARKERS=URI: $arg');
      exitCode = 1;
      return;
    }
    importRules.add(
      ContractImportRule(
        markers: spec.substring(0, split).split(','),
        import: spec.substring(split + 1),
      ),
    );
  }

  final filteredArgs = args
      .where(
        (a) =>
            a != '--clean' &&
            a != '--analyze-only' &&
            !a.startsWith('--stage-dir=') &&
            !a.startsWith('--package=') &&
            !a.startsWith('--contract-import='),
      )
      .toList();

  final stageDir = Directory(
    valueOf('--stage-dir') ??
        '${Directory.systemTemp.path}/contracts_workspace',
  );

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

  final stagedRootNames = <String>{
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'dart_test.yaml',
    package,
  };
  for (final entity in workspaceRoot.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name.startsWith('.') || stagedRootNames.contains(name)) continue;
    stagedRootNames.add(name);

    final linkPath = '${stageDir.path}/$name';
    var type = FileSystemEntity.typeSync(linkPath, followLinks: false);
    if (type == FileSystemEntityType.link &&
        Link(linkPath).targetSync() != entity.absolute.path) {
      Link(linkPath).deleteSync();
      type = FileSystemEntityType.notFound;
    }
    if (type == FileSystemEntityType.notFound) {
      Link(linkPath).createSync(entity.absolute.path);
    }
  }

  // Drop stage entries whose source is gone. A workspace member that was
  // renamed or removed would otherwise stay as a dangling link, and the staged
  // pubspec would not resolve.
  for (final entity in stageDir.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name.startsWith('.') || stagedRootNames.contains(name)) continue;
    if (entity is Link) {
      entity.deleteSync();
    } else if (entity is Directory) {
      entity.deleteSync(recursive: true);
    } else {
      entity.deleteSync();
    }
  }

  final srcPackage = Directory('${workspaceRoot.path}/$package');
  final stagedPackage = Directory('${stageDir.path}/$package');
  stagedPackage.createSync(recursive: true);

  for (final entity in srcPackage.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (name.startsWith('.') || name == 'lib') continue;

    final targetPath = '${stagedPackage.path}/$name';
    var type = FileSystemEntity.typeSync(targetPath, followLinks: false);
    if (type == FileSystemEntityType.link &&
        Link(targetPath).targetSync() != entity.absolute.path) {
      Link(targetPath).deleteSync();
      type = FileSystemEntityType.notFound;
    }
    if (type == FileSystemEntityType.notFound) {
      Link(targetPath).createSync(entity.absolute.path);
    }
  }

  final srcLib = Directory('${srcPackage.path}/lib');
  final stagedLib = Directory('${stagedPackage.path}/lib');
  stagedLib.createSync(recursive: true);

  var transformedCount = 0;
  var symlinkCount = 0;

  final stagedPaths = <String>{};

  for (final entity in srcLib.listSync(recursive: true)) {
    final relative = entity.path.substring(srcLib.path.length + 1);
    final targetPath = '${stagedLib.path}/$relative';
    stagedPaths.add(targetPath);

    if (entity is Directory) {
      Directory(targetPath).createSync(recursive: true);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final transformed = transformContracts(content, importRules: importRules);

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
        } else if (existingType == FileSystemEntityType.link &&
            Link(targetPath).targetSync() != entity.absolute.path) {
          // The stage directory is reused across runs. A link from an earlier
          // run can point into a tree that no longer exists, for example a
          // temporary workspace, which fails the build with a confusing
          // "No such file or directory".
          Link(targetPath).deleteSync();
        }
        if (FileSystemEntity.typeSync(targetPath, followLinks: false) ==
            FileSystemEntityType.notFound) {
          Link(targetPath).createSync(entity.absolute.path);
        }
        symlinkCount++;
      }
    }
  }

  // Remove staged entries whose source is gone, so a deleted library does not
  // linger and keep compiling.
  for (final entity in stagedLib.listSync(recursive: true).reversed) {
    if (stagedPaths.contains(entity.path)) continue;
    if (entity is Directory) {
      if (entity.listSync().isEmpty) entity.deleteSync();
    } else {
      entity.deleteSync();
    }
  }

  stdout.writeln(
    'Staged $package/lib: $transformedCount transformed, '
    '$symlinkCount symlinked.',
  );

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
      await Process.run(Platform.resolvedExecutable, [
        'pub',
        'get',
      ], workingDirectory: stageDir.path);
    }
  }

  if (analyzeOnly) {
    // Clause text is invisible to the analyzer until it is woven in, so a
    // clause naming something that has been renamed rots silently. Analyzing
    // the woven copy catches that.
    //
    // Only errors count. A rotten clause names something that does not exist,
    // which is an error. Warnings and lints report on generated code that no
    // one reads, for example a `return` of a future inside the generated try
    // that wraps a body in an invariant check.
    stdout.writeln('Analyzing woven sources...');
    final analyzeResult = await Process.run(Platform.resolvedExecutable, [
      'analyze',
      '--format=machine',
      'lib',
    ], workingDirectory: stagedPackage.path);
    final errors = LineSplitter.split(
      analyzeResult.stdout as String,
    ).where((line) => line.startsWith('ERROR|')).toList();
    if (errors.isEmpty) {
      stdout.writeln('Contract clauses analyze clean.');
      return;
    }
    for (final error in errors) {
      // SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE
      final fields = error.split('|');
      stderr.writeln(
        '${fields[3]}:${fields[4]}:${fields[5]} ${fields.last} '
        '- ${fields[2].toLowerCase()}',
      );
    }
    stderr.writeln(
      '${errors.length} '
      '${errors.length == 1 ? 'error' : 'errors'} in woven sources.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Running tests against woven sources...');
  final hasTimeout = filteredArgs.any(
    (a) => a == '--timeout' || a.startsWith('--timeout='),
  );
  final hasConcurrency = filteredArgs.any(
    (a) =>
        a == '-j' ||
        a.startsWith('-j') ||
        a == '--concurrency' ||
        a.startsWith('--concurrency='),
  );
  final defaultFlags = <String>[
    if (!hasTimeout) '--timeout=4x',
    if (!hasConcurrency) '-j4',
  ];
  final testProcess = await Process.start(
    Platform.resolvedExecutable,
    ['test', ...defaultFlags, ...filteredArgs],
    workingDirectory: stagedPackage.path,
    mode: ProcessStartMode.inheritStdio,
  );

  exitCode = await testProcess.exitCode;
}
