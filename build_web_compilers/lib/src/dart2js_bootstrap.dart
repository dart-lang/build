// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_modules/build_modules.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:scratch_space/scratch_space.dart';

import 'common.dart';
import 'platforms.dart';
import 'web_entrypoint_builder.dart';

/// Compiles an the primary input of [buildStep] with dart2js.
Future<void> bootstrapDart2Js(
  BuildStep buildStep,
  List<String> dart2JsArgs, {
  required bool nativeNullAssertions,
  required bool nullAssertions,
  required bool soundNullSafety,
}) =>
    _resourcePool.withResource(() => _bootstrapDart2Js(buildStep, dart2JsArgs,
        nativeNullAssertions: nativeNullAssertions,
        nullAssertions: nullAssertions,
        soundNullSafety: soundNullSafety));

Future<void> _bootstrapDart2Js(
  BuildStep buildStep,
  List<String> dart2JsArgs, {
  required bool nativeNullAssertions,
  required bool nullAssertions,
  required bool soundNullSafety,
}) async {
  var dartEntrypointId = buildStep.inputId;
  var moduleId =
      dartEntrypointId.changeExtension(moduleExtension(dart2jsPlatform));
  var args = <String>[];
  {
    var module = Module.fromJson(
        json.decode(await buildStep.readAsString(moduleId))
            as Map<String, dynamic>);
    List<Module> allDeps;
    try {
      allDeps = (await module.computeTransitiveDependencies(buildStep,
          throwIfUnsupported: true))
        ..add(module);
    } on UnsupportedModules catch (e) {
      var librariesString = (await e.exactLibraries(buildStep).toList())
          .map((lib) => AssetId(lib.id.package,
              lib.id.path.replaceFirst(moduleLibraryExtension, '.dart')))
          .join('\n');
      log.warning('''
Skipping compiling ${buildStep.inputId} with dart2js because some of its
transitive libraries have sdk dependencies that are not supported on this platform:

$librariesString

https://github.com/dart-lang/build/blob/master/docs/faq.md#how-can-i-resolve-skipped-compiling-warnings
''');
      return;
    }

    var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    var allSrcs = allDeps.expand((module) => module.sources);
    await scratchSpace.ensureAssets(allSrcs, buildStep);

    var dartUri = dartEntrypointId.path.startsWith('lib/')
        ? Uri.parse('package:${dartEntrypointId.package}/'
            '${dartEntrypointId.path.substring('lib/'.length)}')
        : Uri.parse('$multiRootScheme:///${dartEntrypointId.path}');
    var jsOutputPath = p.withoutExtension(dartUri.scheme == 'package'
            ? 'packages/${dartUri.path}'
            : dartUri.path.substring(1)) +
        jsEntrypointExtension;
    var librariesSpec = p.joinAll([sdkDir, 'lib', 'libraries.json']);
    _validateUserArgs(dart2JsArgs);
    args = dart2JsArgs.toList()
      ..addAll([
        '--libraries-spec=$librariesSpec',
        '--packages=$multiRootScheme:///.dart_tool/package_config.json',
        '--multi-root-scheme=$multiRootScheme',
        '--multi-root=${scratchSpace.tempDir.uri.toFilePath()}',
        for (var experiment in enabledExperiments)
          '--enable-experiment=$experiment',
        '--${nativeNullAssertions ? '' : 'no-'}native-null-assertions',
        if (nullAssertions) '--null-assertions',
        '--${soundNullSafety ? '' : 'no-'}sound-null-safety',
        '-o$jsOutputPath',
        '$dartUri',
      ]);
  }

  log.info('Running dart2js with ${args.join(' ')}\n');
  var result = await Process.run(
      p.join(sdkDir, 'bin', 'dart'),
      [
        ..._dart2jsVmArgs,
        p.join(sdkDir, 'bin', 'snapshots', 'dart2js.dart.snapshot'),
        ...args,
      ],
      workingDirectory: scratchSpace.tempDir.path);
  var jsOutputId = dartEntrypointId.changeExtension(jsEntrypointExtension);
  var jsOutputFile = scratchSpace.fileFor(jsOutputId);
  if (result.exitCode == 0 && await jsOutputFile.exists()) {
    log.info('${result.stdout}\n${result.stderr}');
    var rootDir = p.dirname(jsOutputFile.path);
    var dartFile = p.basename(dartEntrypointId.path);
    var fileGlob = Glob('$dartFile.js*');
    var archive = Archive();
    await for (var jsFile in fileGlob.list(root: rootDir)) {
      if (jsFile.path.endsWith(jsEntrypointExtension) ||
          jsFile.path.endsWith(jsEntrypointSourceMapExtension)) {
        // These are explicitly output, and are not part of the archive.
        continue;
      }
      if (jsFile is File) {
        var fileName = p.relative(jsFile.path, from: rootDir);
        var fileStats = await jsFile.stat();
        archive.addFile(ArchiveFile(
            fileName, fileStats.size, await (jsFile as File).readAsBytes())
          ..mode = fileStats.mode
          ..lastModTime = fileStats.modified.millisecondsSinceEpoch);
      }
    }
    if (archive.isNotEmpty) {
      var archiveId =
          dartEntrypointId.changeExtension(jsEntrypointArchiveExtension);
      await buildStep.writeAsBytes(archiveId, TarEncoder().encode(archive));
    }

    // Explicitly write out the original js file and sourcemap - we can't output
    // these as part of the archive because they already have asset nodes.
    await scratchSpace.copyOutput(jsOutputId, buildStep);
    var jsSourceMapId =
        dartEntrypointId.changeExtension(jsEntrypointSourceMapExtension);
    await _copyModifiedSourceMap(jsSourceMapId, scratchSpace, buildStep);
  } else {
    log.severe('ExitCode:${result.exitCode}\nStdOut:\n${result.stdout}\n'
        'StdErr:\n${result.stderr}');
  }
}

/// If [id] exists, modifies it to something the browser can understand and
/// writes it using [writer].
Future<void> _copyModifiedSourceMap(
    AssetId id, ScratchSpace scratchSpace, AssetWriter writer) async {
  var file = scratchSpace.fileFor(id);
  if (await file.exists()) {
    var content = await file.readAsString();
    var json = jsonDecode(content);
    json['sources'] = fixSourceMapSources((json['sources'] as List).cast());
    await writer.writeAsString(id, jsonEncode(json));
  }
}

final _resourcePool = Pool(maxWorkersPerTask);

const _dart2jsVmArgsEnvVar = 'BUILD_DART2JS_VM_ARGS';
final _dart2jsVmArgs = () {
  var env = Platform.environment[_dart2jsVmArgsEnvVar];
  return env?.split(' ') ?? <String>[];
}();

/// Validates that user supplied dart2js args don't overlap with ones that we
/// want you to configure in a different way.
void _validateUserArgs(List<String> args) {
  for (var arg in args) {
    if (arg.endsWith('sound-null-safety')) {
      log.warning(
          'Detected a manual sound null safety dart2js argument `$arg`, '
          'this should be configured using the `sound_null_safety` option on '
          'the build_web_compilers:entrypoint builder instead.');
    } else if (arg.endsWith('native-null-assertions')) {
      log.warning(
          'Detected a manual native null assertions dart2js argument `$arg`, '
          'this should be configured using the `native_null_assertions` '
          'option on the build_web_compilers:entrypoint builder instead.');
    } else if (arg.endsWith('null-assertions')) {
      log.warning(
          'Detected a manual null assertions dart2js argument `$arg`, this '
          'should be configured using the `null_assertions` option on the '
          'build_web_compilers:entrypoint builder instead.');
    } else if (arg.startsWith('--enable-experiment')) {
      log.warning(
          'Detected a manual enable experiment dart2js argument `$arg`, '
          'this should be enabled on the command line instead, for example: '
          '`dart run build_runner --enable-experiment=<experiment> <command>`.');
    }
  }
}
