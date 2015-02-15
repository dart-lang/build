library source_gen.test.annotation_test.classes;

import 'annotations.dart';
import 'package:source_gen/json_serial/json_annotation.dart';

part 'annotated_classes_part.dart';

const localUntypedAnnotation = const PublicAnnotationClass();

const PublicAnnotationClass localTypedAnnotation =
    const PublicAnnotationClass();

@PublicAnnotationClass()
class CtorNoParams {}

@PublicAnnotationClass.withAnIntAsOne()
class NonDefaultCtorNoParams {}

@PublicAnnotationClass.withPositionalArgs(42, 'custom value')
class NonDefaultCtorWithPositionalParams {}

@PublicAnnotationClass.withPositionalArgs(43, 'another value',
    boolArg: true, listArg: const [5, 6, 7])
class NonDefaultCtorWithPositionalAndNamedParams {}

@PublicAnnotationClass.withKids()
class WithNestedObjects {}

@objectAnnotation
class WithSymbol {}

@JsonSerializable()
class AnnotatedWithJson {}

@localTypedAnnotation
class WithLocalTypedField {}

@localUntypedAnnotation
class WithLocalUntypedField {}

@typedAnnotation
class WithTypedField {}

@untypedAnnotation
class WithUntypedField {}

@untypedAnnotationWithNonDefaultCtor
class WithAFieldFromNonDefaultCtor {}
