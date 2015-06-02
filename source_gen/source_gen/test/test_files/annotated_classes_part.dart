part of source_gen.test.annotation_test.classes;

const localUntypedAnnotationInPart = const PublicAnnotationClass();

const PublicAnnotationClass localTypedAnnotationInPart =
    const PublicAnnotationClass();

@PublicAnnotationClass()
class CtorNoParamsInPart {}

@PublicAnnotationClassInPart()
class CtorNoParamsFromPartInPart {}
