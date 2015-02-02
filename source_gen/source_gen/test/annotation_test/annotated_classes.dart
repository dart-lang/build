library source_gen.test.annotation_test.classes;

import 'annotations.dart';

part 'annotated_classes_part.dart';

const localUntypedAnnotation = const PublicAnnotationClass();

const PublicAnnotationClass localTypedAnnotation =
    const PublicAnnotationClass();

@PublicAnnotationClass()
class CtorNoParams {}
