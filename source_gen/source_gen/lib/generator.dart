library source_gen;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';

import 'annotations.dart';

abstract class Generator {
  const Generator();

  GeneratorAnnotation get annotation;

  String generateClassHelpers(
      Annotation annotation, ClassDeclaration classDef) {
    throw new UnimplementedError();
  }
}
