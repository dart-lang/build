// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

/// Copy the input asset to all possible output assets.
void _defaultBehavior(
        BuildStep buildStep, Map<String, List<String>> buildExtensions) =>
    _copyToAll(buildStep, buildExtensions, (id) => id);

void _copyToAll(BuildStep buildStep, Map<String, List<String>> buildExtensions,
    AssetId Function(AssetId) readFrom) {
  if (!buildExtensions.keys.any((e) => buildStep.inputId.path.endsWith(e))) {
    throw new ArgumentError('Only expected inputs with extension in '
        '${buildExtensions.keys.toList()} but got ${buildStep.inputId}');
  }
  for (final inputExtension in buildExtensions.keys) {
    if (!buildStep.inputId.path.endsWith(inputExtension)) continue;
    for (final outputExtension in buildExtensions[inputExtension]) {
      final newPath = _replaceSuffix(
          buildStep.inputId.path, inputExtension, outputExtension);
      final id = new AssetId(buildStep.inputId.package, newPath);
      buildStep.writeAsString(
          id, buildStep.readAsString(readFrom(buildStep.inputId)));
    }
  }
}

FutureOr Function(BuildStep, Map<String, List<String>>) copyFrom(
        AssetId assetId) =>
    (buildStep, buildExtensions) =>
        _copyToAll(buildStep, buildExtensions, (_) => assetId);

Map<String, List<String>> appendExtension(String postFix,
        {String from: '', int numCopies: 1}) =>
    {
      from: numCopies == 1
          ? ['$from$postFix']
          : new List.generate(numCopies, (i) => '$from$postFix.$i')
    };

Map<String, List<String>> replaceExtension(String from, String to) => {
      from: [to]
    };

/// A [Builder] whose [build] method can be replaced with a closure.
class TestBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  final FutureOr Function(BuildStep, Map<String, List<String>>) _build;
  final FutureOr Function(BuildStep, Map<String, List<String>>) _extraWork;

  /// A stream of all the [BuildStep.inputId]s that are seen.
  ///
  /// Events are added at the top of the [build] method.
  final _buildInputsController = new StreamController<AssetId>.broadcast();
  Stream<AssetId> get buildInputs => _buildInputsController.stream;

  TestBuilder({
    Map<String, List<String>> buildExtensions,
    FutureOr Function(BuildStep, Map<String, List<String>>) build,
    FutureOr Function(BuildStep, Map<String, List<String>>) extraWork,
  })
      : buildExtensions = buildExtensions ?? appendExtension('.copy'),
        _build = build ?? _defaultBehavior,
        _extraWork = extraWork;

  @override
  Future build(BuildStep buildStep) async {
    if (buildStep.inputId.path.endsWith(r'$')) return;
    _buildInputsController.add(buildStep.inputId);
    await _build(buildStep, buildExtensions);
    if (_extraWork != null) await _extraWork(buildStep, buildExtensions);
  }
}

String _replaceSuffix(String path, String old, String replacement) =>
    path.substring(0, path.length - old.length) + replacement;
