library source_gen.json_serial.generator;

import 'dart:async';
import 'package:analyzer/src/generated/element.dart';

import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/utils.dart';

import 'json_serializable.dart';

// TODO: assumes there is a empty, default ctor
// TODO: assumes all fields are set-able
class JsonSerializableGenerator
    extends GeneratorForAnnotation<JsonSerializable> {
  const JsonSerializableGenerator();

  @override
  Future<String> generateForAnnotatedElement(
      Element element, JsonSerializable annotation) async {
    if (element is! ClassElement) {
      var friendlyName = frieldlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JsonSerializable annotation from `$friendlyName`.');
    }

    var classElement = element as ClassElement;
    var className = classElement.name;

    var finalFields = new Set<String>();

    var fields = <String, String>{};
    for (FieldElement field in classElement.fields) {
      if (field.isFinal) {
        finalFields.add(field.name);
      }
      fields[field.name] = field.type.name;
    }

    if (finalFields.isNotEmpty) {
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$className`.',
          todo: 'Make the following fields writable: ${finalFields.join(', ')}.');
    }

    var prefix = '_\$${className}';

    var buffer = new StringBuffer();

    if (annotation.createFactory) {

      //
      // Generate the static factory method
      //
      buffer.writeln();
      buffer
          .writeln('$className ${prefix}FromJson(Map<String, Object> json) =>');
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
    }

    if (annotation.createToJson) {
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
    }

    return buffer.toString();
  }

  @override
  String toString() => 'JsonGenerator';
}
