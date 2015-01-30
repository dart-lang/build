library dart_source_gen.json_serial.generator;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';

import 'package:dart_source_gen/generator.dart';
import 'package:dart_source_gen/annotations.dart';

import 'json_annotation.dart';

const Generator generator = const _JsonGenerator();

class _JsonGenerator extends Generator {
  const _JsonGenerator();

  GeneratorAnnotation get annotation => const JsonSerializable();

  String generateClassHelpers(
      Annotation annotation, ClassDeclaration classDef) {
    var className = classDef.name.name;

    var fieldMap = <String, String>{};
    for (var member in classDef.members) {
      if (member is FieldDeclaration) {
        var fields = member.fields;
        var typeName = fields.type.name.name;
        for (var field in fields.variables) {
          fieldMap[field.name.name] = typeName;
        }
      }
    }

    return _populateTemplate(className, fieldMap);
  }
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
  fields.forEach((k, v) {
    buffer.writeln("    '$k': $k,");
  });

  buffer.writeln('  };');

  buffer.write('}');

  return buffer.toString();
}
