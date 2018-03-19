// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'web_entrypoint_builder.dart';

Future<Null> bootstrapDart2Js(
    BuildStep buildStep, List<String> dart2JsArgs) async {
  var dartEntrypointId = buildStep.inputId;
  var moduleId = dartEntrypointId.changeExtension(moduleExtension);
  var module = new Module.fromJson(json
      .decode(await buildStep.readAsString(moduleId)) as Map<String, dynamic>);
  var allDeps = (await module.computeTransitiveDependencies(buildStep))
    ..add(module);
  var allSrcs = allDeps.expand((module) => module.sources);
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  await scratchSpace.ensureAssets(allSrcs, buildStep);

  var packageFile = await _createPackageFile(allSrcs, buildStep, scratchSpace);

  var jsOutputId = dartEntrypointId.changeExtension(jsEntrypointExtension);
  var args = dart2JsArgs.toList()
    ..addAll([
      '--packages=$packageFile',
      '-o${jsOutputId.path}',
      dartEntrypointId.path,
    ]);
  var dart2js = await buildStep.fetchResource(dart2JsWorkerResource);
  var result = await dart2js.compile(args);
  var jsOutputFile = scratchSpace.fileFor(jsOutputId);
  if (result.succeeded && await jsOutputFile.exists()) {
    log.info(result.output);
    var rootDir = p.dirname(jsOutputFile.path);
    var dartFile = p.basename(dartEntrypointId.path);
    var fileGlob = new Glob('$dartFile.js*');
    var archive = new Archive();
    await for (var jsFile in fileGlob.list(root: rootDir)) {
      if (jsFile.path.endsWith(jsEntrypointExtension) ||
          jsFile.path.endsWith(jsEntrypointSourceMapExtension)) {
        // These are explicitly output, and are not part of the archive.
        continue;
      }
      if (jsFile is File) {
        var fileName = p.relative(jsFile.path, from: rootDir);
        var fileStats = await jsFile.stat();
        archive.addFile(new ArchiveFile(
            fileName, fileStats.size, await jsFile.readAsBytes())
          ..mode = fileStats.mode
          ..lastModTime = fileStats.modified.millisecondsSinceEpoch);
      }
    }
    if (archive.isNotEmpty) {
      var archiveId =
          dartEntrypointId.changeExtension(jsEntrypointArchiveExtension);
      await buildStep.writeAsBytes(archiveId, new TarEncoder().encode(archive));
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

Future<Null> _copyIfExists(
    AssetId id, ScratchSpace scratchSpace, AssetWriter writer) async {
  var file = scratchSpace.fileFor(id);
  if (await file.exists()) {
    await scratchSpace.copyOutput(id, writer);
  }
}

/// Creates a `.packages` file unique to this entrypoint at the root of the
/// scratch space and returns it's filename.
///
/// Since mulitple invocations of Dart2Js will share a scratch space and we only
/// know the set of packages involved the current entrypoint we can't construct
/// a `.packages` file that will work for all invocations of Dart2Js so a unique
/// file is created for every entrypoint that is run.
///
/// The filename is based off the MD5 hash of the asset path so that files are
/// unique regarless of situations like `web/foo/bar.dart` vs
/// `web/foo-bar.dart`.
Future<String> _createPackageFile(Iterable<AssetId> inputSources,
    BuildStep buildStep, ScratchSpace scratchSpace) async {
  var inputUri = buildStep.inputId.uri;
  var packageFileName =
      '.package-${md5.convert(inputUri.toString().codeUnits)}';
  var packagesFile = scratchSpace
      .fileFor(new AssetId(buildStep.inputId.package, packageFileName));
  var packageNames = inputSources.map((s) => s.package).toSet();
  var packagesFileContent =
      packageNames.map((n) => '$n:packages/$n/').join('\n');
  await packagesFile
      .writeAsString('# Generated for $inputUri\n$packagesFileContent');
  return packageFileName;
}
