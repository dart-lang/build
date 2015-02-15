library source_gen.test.annotation_test.defs;

part 'annotation_part.dart';

const untypedAnnotation = const PublicAnnotationClass();

const PublicAnnotationClass typedAnnotation = const PublicAnnotationClass();

class PublicAnnotationClass {
  final int anInt;
  final String aString;
  final List<int> aListOfInt;
  final bool aBool;

  const PublicAnnotationClass()
      : anInt = 0,
        aString = 'str',
        aListOfInt = const [1, 2, 3],
        aBool = false;

  const PublicAnnotationClass.withAnIntAsOne()
      : anInt = 1,
        aString = 'str',
        aListOfInt = const [1, 2, 3],
        aBool = false;

  const PublicAnnotationClass.withPositionalArgs(int intArg, this.aString,
      {bool boolArg: false})
      : anInt = intArg,
        aListOfInt = const [1, 2, 3],
        aBool = boolArg;
}
