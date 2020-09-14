// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'platforms.dart';
import 'web_entrypoint_builder.dart';

/// Compiles an the primary input of [buildStep] with dart2js.
///
/// If [skipPlatformCheck] is `true` then all `dart:` imports will be
/// allowed in all packages.
Future<void> bootstrapDart2Js(BuildStep buildStep, List<String> dart2JsArgs,
    {bool skipPlatformCheck}) async {
  skipPlatformCheck ??= false;
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
          throwIfUnsupported: !skipPlatformCheck))
        ..add(module);
    } on UnsupportedModules catch (e) {
      var librariesString = (await e.exactLibraries(buildStep).toList())
          .map((lib) => AssetId(lib.id.package,
              lib.id.path.replaceFirst(moduleLibraryExtension, '.dart')))
          .join('\n');
      log.warning('''
Skipping compiling ${buildStep.inputId} with dart2js because some of its
transitive libraries have sdk dependencies that not supported on this platform:

$librariesString

https://github.com/dart-lang/build/blob/master/docs/faq.md#how-can-i-resolve-skipped-compiling-warnings
''');
      return;
    }

    var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    var allSrcs = allDeps.expand((module) => module.sources);
    await scratchSpace.ensureAssets(allSrcs, buildStep);

    var dartPath = dartEntrypointId.path.startsWith('lib/')
        ? 'package:${dartEntrypointId.package}/'
            '${dartEntrypointId.path.substring('lib/'.length)}'
        : dartEntrypointId.path;
    var jsOutputPath =
        '${p.withoutExtension(dartPath.replaceFirst('package:', 'packages/'))}'
        '$jsEntrypointExtension';
    args = dart2JsArgs.toList()
      ..addAll([
        '--packages=${p.join('.dart_tool', 'package_config.json')}',
        '-o$jsOutputPath',
        dartPath,
      ]);
  }

  var dart2js = await buildStep.fetchResource(dart2JsWorkerResource);
  var result = await dart2js.compile(args);
  var jsOutputId = dartEntrypointId.changeExtension(jsEntrypointExtension);
  var jsOutputFile = scratchSpace.fileFor(jsOutputId);
  if (result.succeeded && await jsOutputFile.exists()) {
    log.info(result.output);
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
        archive.addFile(
            ArchiveFile(fileName, fileStats.size, await jsFile.readAsBytes())
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
    await _copyIfExists(jsSourceMapId, scratchSpace, buildStep);
  } else {
    log.severe(result.output);
  }
}

Future<void> _copyIfExists(
    AssetId id, ScratchSpace scratchSpace, AssetWriter writer) async {
  var file = scratchSpace.fileFor(id);
  if (await file.exists()) {
    await scratchSpace.copyOutput(id, writer);
  }
}
