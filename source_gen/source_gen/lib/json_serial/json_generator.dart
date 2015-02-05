library source_gen.json_serial.generator;

import 'package:analyzer/src/generated/element.dart';

import 'package:source_gen/src/generator.dart';
import 'package:source_gen/src/utils.dart';

import 'json_annotation.dart';

// TODO: assumes there is a empty, default ctor
// TODO: assumes all fields are set-able
class JsonGenerator extends GeneratorForAnnotation<JsonSerializable> {
  const JsonGenerator();

  @override
  String generateForAnnotatedElement(
      Element element, JsonSerializable annotation) {
    if (element is! ClassElement) {
      var friendlyName = frieldlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JsonSerializable annotation from `$friendlyName`.');
    }

    var classElement = element as ClassElement;

    var finalFields = new Set<String>();

    var fieldMap = <String, String>{};
    for (FieldElement field in classElement.fields) {
      if (field.isFinal) {
        finalFields.add(field.name);
      }
      fieldMap[field.name] = field.type.name;
    }

    if (finalFields.isNotEmpty) {
      var friendlyName = frieldlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Make the following fields writable: ${finalFields.join(', ')}.');
    }

    return _populateTemplate(classElement.displayName, fieldMap);
  }

  @override
  String toString() => 'JsonGenerator';
}

String _populateTemplate(String className, Map<String, String> fields) {
  var prefix = '_\$${className}';

  var buffer = new StringBuffer();

  //
  // Generate the static factory method
  //
  buffer.writeln();
  buffer.writeln('$className ${prefix}FromJson(Map<String, Object> json) =>');
  buffer.write('    new $className()');
  if (fields.isEmpty) {
    buffer.writeln(';');
  } else {
    fields.forEach((name, type) {
      buffer.writeln();
      buffer.write("      ..${name} = json['$name']");
    });
    buffer.writeln(';');
  }
  buffer.writeln();

  //
  // Generate the mixin class
  //
  buffer.writeln('abstract class ${prefix}SerializerMixin {');

  // write fields
  fields.forEach((k, v) {
    buffer.writeln('  $v get $k;');
  });

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
