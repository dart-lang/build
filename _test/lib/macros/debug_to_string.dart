import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class DebugToString implements ClassDeclarationsMacro {
  const DebugToString();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final fields = await builder.fieldsOf(clazz);
    builder.declareInType(DeclarationCode.fromParts([
      'String debugToString() => """\n${clazz.identifier.name} {\n',
      for (var field in fields) ...[
        '  ${field.identifier.name}: \${',
        field.identifier,
        '}\n',
      ],
      '}""";',
    ]));
  }
}
