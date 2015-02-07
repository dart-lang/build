library source_gen.test.annotation_test.classes;

import 'annotations.dart';
import 'package:source_gen/json_serial/json_annotation.dart';

part 'annotated_classes_part.dart';

const localUntypedAnnotation = const PublicAnnotationClass();

const PublicAnnotationClass localTypedAnnotation =
    const PublicAnnotationClass();

@PublicAnnotationClass()
class CtorNoParams {}

@JsonSerializable()
class AnnotatedWithJson {}
