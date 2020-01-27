// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

/// Overridable behavior for a [Builder.build] method.
typedef BuildBehavior = FutureOr Function(
    BuildStep buildStep, Map<String, List<String>> buildExtensions);

/// Copy the input asset to all possible output assets.
void _defaultBehavior(
        BuildStep buildStep, Map<String, List<String>> buildExtensions) =>
    _copyToAll(buildStep, buildExtensions);

T _identity<T>(T value) => value;
Future<String> _readAsset(BuildStep buildStep, AssetId assetId) =>
    buildStep.readAsString(assetId);

/// Pass the input assetId through [readFrom] and duplicate the results of
/// [read] on that asset into every matching output based on [buildExtensions].
void _copyToAll(BuildStep buildStep, Map<String, List<String>> buildExtensions,
    {AssetId Function(AssetId assetId) readFrom = _identity,
    Future<String> Function(BuildStep buildStep, AssetId assetId) read =
        _readAsset}) {
  if (!buildExtensions.keys.any((e) => buildStep.inputId.path.endsWith(e))) {
    throw ArgumentError('Only expected inputs with extension in '
        '${buildExtensions.keys.toList()} but got ${buildStep.inputId}');
  }
  for (final inputExtension in buildExtensions.keys) {
    if (!buildStep.inputId.path.endsWith(inputExtension)) continue;
    for (final outputExtension in buildExtensions[inputExtension]) {
      final newPath = _replaceSuffix(
          buildStep.inputId.path, inputExtension, outputExtension);
      final id = AssetId(buildStep.inputId.package, newPath);
      buildStep.writeAsString(id, read(buildStep, readFrom(buildStep.inputId)));
    }
  }
}

/// A build behavior which reads [assetId] and copies it's content into every
/// output.
BuildBehavior copyFrom(AssetId assetId) => (buildStep, buildExtensions) =>
    _copyToAll(buildStep, buildExtensions, readFrom: (_) => assetId);

/// A build behavior which writes either 'true' or 'false' depending on whether
/// [assetId] can be read.
BuildBehavior writeCanRead(AssetId assetId) =>
    (BuildStep buildStep, Map<String, List<String>> buildExtensions) =>
        _copyToAll(buildStep, buildExtensions,
            readFrom: (_) => assetId,
            read: (buildStep, assetId) async =>
                '${await buildStep.canRead(assetId)}');

/// A [Builder.buildExtensions] which operats on assets ending in [from] and
/// creates outputs with [postFix] appended as the extension.
///
/// If [numCopies] is greater than 1 the postFix will also get a `.0`, `.1`...
Map<String, List<String>> appendExtension(String postFix,
        {String from = '', int numCopies = 1}) =>
    {
      from: numCopies == 1
          ? ['$from$postFix']
          : List.generate(numCopies, (i) => '$from$postFix.$i')
    };

Map<String, List<String>> replaceExtension(String from, String to) => {
      from: [to]
    };

/// A [Builder] whose [build] method can be replaced with a closure.
class TestBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  final BuildBehavior _build;
  final BuildBehavior _extraWork;

  /// A stream of all the [BuildStep.inputId]s that are seen.
  ///
  /// Events are added at the start of the [build] method.
  final _buildInputsController = StreamController<AssetId>.broadcast();
  Stream<AssetId> get buildInputs => _buildInputsController.stream;

  /// A stream of all the [BuildStep.inputId]s that are completed.
  ///
  /// Events are added at the end of the [build] method.
  final _buildsCompletedController = StreamController<AssetId>.broadcast();
  Stream<AssetId> get buildsCompleted => _buildsCompletedController.stream;

  TestBuilder({
    Map<String, List<String>> buildExtensions,
    BuildBehavior build,
    BuildBehavior extraWork,
  })  : buildExtensions = buildExtensions ?? appendExtension('.copy'),
        _build = build ?? _defaultBehavior,
        _extraWork = extraWork;

  @override
  Future build(BuildStep buildStep) async {
    if (!await buildStep.canRead(buildStep.inputId)) return;
    _buildInputsController.add(buildStep.inputId);
    await _build(buildStep, buildExtensions);
    if (_extraWork != null) await _extraWork(buildStep, buildExtensions);
    _buildsCompletedController.add(buildStep.inputId);
  }
}

String _replaceSuffix(String path, String old, String replacement) =>
    path.substring(0, path.length - old.length) + replacement;
