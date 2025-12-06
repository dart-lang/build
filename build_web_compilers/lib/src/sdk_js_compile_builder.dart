// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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
  /// The SDK kernel file for the current sdk.
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

  /// Enables canary features in DDC.
  final bool canaryFeatures;

  /// Emits DDC code using its Library Bundle module system.
  final bool ddcLibraryBundle;

  SdkJsCompileBuilder({
    required this.sdkKernelPath,
    required String outputPath,
    String? librariesPath,
    String? platformSdk,
    required this.canaryFeatures,
    required this.ddcLibraryBundle,
  }) : platformSdk = platformSdk ?? sdkDir,
       librariesPath =
           librariesPath ??
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
    await _createDevCompilerModule(
      buildStep,
      platformSdk,
      sdkKernelPath,
      librariesPath,
      jsOutputId,
      canaryFeatures,
      ddcLibraryBundle,
    );
  }
}

/// Compile the sdk module with the dev compiler.
Future<void> _createDevCompilerModule(
  BuildStep buildStep,
  String dartSdk,
  String sdkKernelPath,
  String librariesPath,
  AssetId jsOutputId,
  bool canaryFeatures,
  bool ddcLibraryBundle,
) async {
  final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
  final jsOutputFile = scratchSpace.fileFor(jsOutputId);

  ProcessResult result;
  try {
    // Use standalone process instead of the worker due to
    // https://github.com/dart-lang/sdk/issues/49441
    var snapshotPath = p.join(
      sdkDir,
      'bin',
      'snapshots',
      'dartdevc_aot.dart.snapshot',
    );
    final execSuffix = Platform.isWindows ? '.exe' : '';
    var dartPath = p.join(sdkDir, 'bin', 'dartaotruntime$execSuffix');
    if (!File(snapshotPath).existsSync()) {
      snapshotPath = p.join(
        sdkDir,
        'bin',
        'snapshots',
        'dartdevc.dart.snapshot',
      );
      dartPath = p.join(sdkDir, 'bin', 'dart$execSuffix');
    }
    result = await Process.run(dartPath, [
      snapshotPath,
      '--multi-root-scheme=org-dartlang-sdk',
      '--modules=${ddcLibraryBundle ? 'ddc' : 'amd'}',
      if (canaryFeatures || ddcLibraryBundle) '--canary',
      '--module-name=dart_sdk',
      '-o',
      jsOutputFile.path,
      p.url.join(dartSdk, sdkKernelPath),
    ]);
  } catch (e) {
    throw DartDevcCompilationException(jsOutputId, e.toString());
  }

  final message = '${result.stdout}${result.stderr}'
      .replaceAll('${scratchSpace.tempDir.path}/', '')
      .replaceAll('org-dartlang-sdk:///', '');
  if (result.exitCode != EXIT_CODE_OK ||
      !jsOutputFile.existsSync() ||
      message.contains('Error:')) {
    throw DartDevcCompilationException(jsOutputId, message);
  }

  if (message.isNotEmpty) {
    log.info('\n$message');
  }

  // Copy the output back using the buildStep.
  await scratchSpace.copyOutput(jsOutputId, buildStep);

  await fixAndCopySourceMap(
    jsOutputId.changeExtension(_jsSourceMapExtension),
    scratchSpace,
    buildStep,
  );
}
