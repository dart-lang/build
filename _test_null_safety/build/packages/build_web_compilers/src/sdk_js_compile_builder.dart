// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;

import 'common.dart';
import 'errors.dart';

const _jsSourceMapExtension = '.js.map';

/// A builder which can compile the SDK to JS from kernel.
class SdkJsCompileBuilder implements Builder {
  /// The SDK kernel file for the current sdk and configuration (sound vs
  /// unsound, etc).
  ///
  /// This is exactly what will be compiled into the resulting JS file.
  final String sdkKernelPath;

  /// The root directory of the platform's dart SDK.
  ///
  /// If not provided, defaults to the directory of
  /// [Platform.resolvedExecutable].
  ///
  /// On flutter this is the path to the root of the flutter_patched_sdk
  /// directory, which contains the platform kernel files.
  final String platformSdk;

  /// The absolute path to the libraries file for the current platform.
  ///
  /// If not provided, defaults to "lib/libraries.json" in the sdk directory.
  final String librariesPath;

  /// The final destination for the compiled JS file.
  final AssetId jsOutputId;

  final bool soundNullSafety;

  SdkJsCompileBuilder({
    required this.sdkKernelPath,
    required String outputPath,
    required this.soundNullSafety,
    String? librariesPath,
    String? platformSdk,
  })  : platformSdk = platformSdk ?? sdkDir,
        librariesPath = librariesPath ??
            p.join(platformSdk ?? sdkDir, 'lib', 'libraries.json'),
        buildExtensions = {
          r'$package$': [
            outputPath,
            p.setExtension(outputPath, _jsSourceMapExtension),
          ],
        },
        jsOutputId = AssetId('build_web_compilers', outputPath);

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    await _createDevCompilerModule(buildStep, platformSdk, sdkKernelPath,
        librariesPath, jsOutputId, soundNullSafety);
  }
}

/// Compile the sdk module with the dev compiler.
Future<void> _createDevCompilerModule(
  BuildStep buildStep,
  String dartSdk,
  String sdkKernelPath,
  String librariesPath,
  AssetId jsOutputId,
  bool soundNullSafety,
) async {
  var scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  var jsOutputFile = scratchSpace.fileFor(jsOutputId);

  var request = WorkRequest()
    ..arguments.addAll([
      '--multi-root-scheme=org-dartlang-sdk',
      '--modules=amd',
      '--module-name=dart_sdk',
      '--${soundNullSafety ? '' : 'no-'}sound-null-safety',
      '-o',
      jsOutputFile.path,
      p.url.join(dartSdk, sdkKernelPath),
    ]);

  var driverResource = dartdevkDriverResource;
  var driver = await buildStep.fetchResource(driverResource);
  WorkResponse response;
  try {
    response = await driver.doWork(request,
        trackWork: (response) =>
            buildStep.trackStage('Compile', () => response, isExternal: true));
  } catch (e) {
    throw DartDevcCompilationException(jsOutputId, e.toString());
  }

  var message = response.output
      .replaceAll('${scratchSpace.tempDir.path}/', '')
      .replaceAll('org-dartlang-sdk:///', '');
  if (response.exitCode != EXIT_CODE_OK ||
      !jsOutputFile.existsSync() ||
      message.contains('Error:')) {
    throw DartDevcCompilationException(jsOutputId, message);
  }

  if (message.isNotEmpty) {
    log.info('\n$message');
  }

  // Copy the output back using the buildStep.
  await scratchSpace.copyOutput(jsOutputId, buildStep);
  // We need to modify the sources in the sourcemap to remove the custom
  // `multiRootScheme` that we use.
  var sourceMapId = jsOutputId.changeExtension(_jsSourceMapExtension);
  var file = scratchSpace.fileFor(sourceMapId);
  var content = await file.readAsString();
  var json = jsonDecode(content);
  json['sources'] = fixSourceMapSources((json['sources'] as List).cast());
  await buildStep.writeAsString(sourceMapId, jsonEncode(json));
}
