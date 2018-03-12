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

  var jsOutputId = dartEntrypointId.changeExtension(jsEntrypointExtension);
  var args = dart2JsArgs.toList()
    ..addAll([
      '-ppackages',
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
      if (jsFile is File) {
        var fileName = p.relative(jsFile.path, from: rootDir);
        var fileStats = await jsFile.stat();
        archive.addFile(new ArchiveFile(
            fileName, fileStats.size, await jsFile.readAsBytes())
          ..mode = fileStats.mode
          ..lastModTime = fileStats.modified.millisecondsSinceEpoch);
      }
    }
    var archiveId =
        dartEntrypointId.changeExtension(jsEntrypointArchiveExtension);
    await buildStep.writeAsBytes(archiveId, new TarEncoder().encode(archive));
    // await scratchSpace.copyOutput(jsOutputId, buildStep);
    // var jsSourceMapId =
    //     dartEntrypointId.changeExtension(jsEntrypointSourceMapExtension);
    // await _copyIfExists(jsSourceMapId, scratchSpace, buildStep);
    // var dumpInfoId = dartEntrypointId.changeExtension(dumpInfoExtension);
    // await _copyIfExists(dumpInfoId, scratchSpace, buildStep);
  } else {
    log.severe(result.output);
  }
}

// Future<Null> _copyIfExists(
//     AssetId id, ScratchSpace scratchSpace, AssetWriter writer) async {
//   var file = scratchSpace.fileFor(id);
//   if (await file.exists()) {
//     await scratchSpace.copyOutput(id, writer);
//   }
// }
