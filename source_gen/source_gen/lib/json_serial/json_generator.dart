library source_gen.json_serial.generator;

import 'package:analyzer/src/generated/element.dart';

import 'package:source_gen/src/generator.dart';

import 'json_annotation.dart';

class JsonGenerator extends GeneratorForAnnotation<JsonSerializable> {
  const JsonGenerator();

  @override
  String generateForAnnotatedElement(
      Element element, JsonSerializable annotation) {
    if (element is! ClassElement) {
      throw new InvalidGenerationSourceError(
          'Generator cannot target $element.');
    }

    return _generate(element);
  }

  String _generate(ClassElement element) {
    var className = element.displayName;

    var fieldMap = <String, String>{};
    for (var member in element.fields) {
      fieldMap[member.name] = member.type.name;
    }

    return _populateTemplate(className, fieldMap);
  }

  @override
  String toString() => 'JsonGenerator';
}

String _populateTemplate(String className, Map<String, String> fields) {
  var buffer = new StringBuffer();

  buffer.writeln('abstract class _\$_${className}SerializerMixin {');

  // write fields
  fields.forEach((k, v) {
    buffer.writeln('  $v get $k;');
  });

  // write static factory
  buffer.writeln();
  buffer.writeln('  static $className fromJson(Map<String, Object> json) {');
  buffer.write('    return new $className()');
  if (fields.isEmpty) {
    buffer.writeln(';');
  } else {
    fields.forEach((name, type) {
      buffer.writeln();
      buffer.write("      ..${name} = json['$name']");
    });
    buffer.writeln(';');
  }
  buffer.writeln('  }');
  buffer.writeln();

  // write toJson method
  buffer.writeln('  Map<String, Object> toJson() => {');

  var pairs = <String>[];
  fields.forEach((k, v) {
    pairs.add("'$k': $k");
  });
  buffer.writeln(pairs.join(','));

  buffer.writeln('  };');

  buffer.write('}');

  return buffer.toString();
}
