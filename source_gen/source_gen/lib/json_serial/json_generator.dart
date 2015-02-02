library source_gen.json_serial.generator;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:source_gen/src/generator.dart';
import 'package:source_gen/src/utils.dart';

import 'json_annotation.dart';

const Generator generator = const _JsonGenerator();

class _JsonGenerator extends GeneratorForAnnotation<JsonSerializable> {
  const _JsonGenerator();

  CompilationUnitMember generateForAnnotatedElement(
      Element element, JsonSerializable annotation) {
    if (element is ClassElement) {
      return _generate(element);
    }
    return null;
  }

  CompilationUnitMember _generate(ClassElement element) {
    var className = element.displayName;

    var fieldMap = <String, String>{};
    for (var member in element.fields) {
      fieldMap[member.name] = member.type.name;
    }

    var codeStr = _populateTemplate(className, fieldMap);

    var unit = stringToCompilationUnit(codeStr);

    return unit.declarations.single;
  }

  String toString() => 'Sample Json Generator';
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
