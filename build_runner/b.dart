import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions
      => {'.dart': ['.txt']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    final buffer = StringBuffer();
    final library = await resolver.libraryFor(buildStep.inputId);
    for (final clazz in library.classes) {
      buffer.writeln(clazz.name);
      for (final supertype in clazz.allSupertypes) {
        buffer.writeln('  \${supertype.getDisplayString()}');
      }
    }
    await buildStep.writeAsString(
        buildStep.inputId.addExtension('.txt'),
        buffer.toString(),
    );
  }
}
