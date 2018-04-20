// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:json_serializable/type_helper.dart';
import 'package:source_gen/source_gen.dart';

main(List<String> arguments) async {
  var builders = [
    applyToRoot(
        new PartBuilder([
          new JsonSerializableGenerator.withDefaultHelpers(
              [const _AssetIdTypeHelper()])
        ]),
        generateFor: const InputSet(include: const [
          'lib/src/modules.dart',
          'lib/src/meta_module.dart'
        ])),
  ];
  var args = arguments.toList()..add('--delete-conflicting-outputs');
  exitCode = await run(args, builders);
}

const _assetIdTypeChecker = const TypeChecker.fromRuntime(AssetId);

class _AssetIdTypeHelper extends TypeHelper {
  const _AssetIdTypeHelper();

  @override
  String deserialize(DartType targetType, String expression,
      DeserializeContext deserializeNested) {
    if (!_isSupported(targetType)) return null;
    // TODO: Use `commonNullPrefix` if exposed from json_serializable, see
    // https://github.com/dart-lang/json_serializable/issues/53
    var unsafeExpression =
        'new ${targetType.name}.deserialize($expression as List)';
    return deserializeNested.nullable
        ? '$expression == null ? null : $unsafeExpression'
        : unsafeExpression;
  }

  @override
  String serialize(DartType targetType, String expression,
      SerializeContext serializeNested) {
    if (!_isSupported(targetType)) return null;
    return '$expression${serializeNested.nullable ? '?' : ''}.serialize()';
  }

  bool _isSupported(DartType targetType) =>
      _assetIdTypeChecker.isExactlyType(targetType);
}
