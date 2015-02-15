library source_gen.test.annotation_test.defs;

part 'annotation_part.dart';

const untypedAnnotation = const PublicAnnotationClass();

const untypedAnnotationWithNonDefaultCtor =
    const PublicAnnotationClass.withPositionalArgs(5, 'field', boolArg: true);

const PublicAnnotationClass typedAnnotation = const PublicAnnotationClass();

class PublicAnnotationClass {
  final int anInt;
  final String aString;
  final List aList;
  final bool aBool;
  final PublicAnnotationClass child1;
  final PublicAnnotationClass child2;

  const PublicAnnotationClass()
      : anInt = 0,
        aString = 'str',
        aList = const [1, 2, 3],
        aBool = false,
        child1 = null,
        child2 = null;

  const PublicAnnotationClass.withAnIntAsOne()
      : anInt = 1,
        aString = 'str',
        aList = const [1, 2, 3],
        aBool = false,
        child1 = null,
        child2 = null;

  const PublicAnnotationClass.withPositionalArgs(int intArg, this.aString,
      {bool boolArg: false, List listArg: const [2, 3, 4]})
      : anInt = intArg,
        aList = listArg,
        aBool = boolArg,
        child1 = null,
        child2 = null;

  const PublicAnnotationClass.withKids()
      : anInt = 0,
        aList = const [1, 2, 3],
        aBool = false,
        aString = 'withKids',
        child1 = const PublicAnnotationClass(),
        child2 = const PublicAnnotationClass.withAnIntAsOne();
}

const objectAnnotation = const {
  'int': 1,
  'bool': true,
  'list': const [1, 2, 3]
};
