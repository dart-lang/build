library source_gen.json_serial.generator;

import 'dart:async';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/utils.dart';

import 'json_serializable.dart';

// TODO: toJson option to omit null/empty values
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

    // Get all of the fields that need to be assigned
    // TODO: support overriding the field set with an annotation option
    var fields = classElement.fields.fold(<String, FieldElement>{},
        (map, field) {
      map[field.name] = field;
      return map;
    }) as Map<String, FieldElement>;

    // Get the constructor to use for the factory

    var prefix = '_\$${className}';

    var buffer = new StringBuffer();

    if (annotation.createFactory) {
      _writeFactory(buffer, classElement, fields, prefix);
    }

    if (annotation.createToJson) {
      //
      // Generate the mixin class
      //
      buffer.writeln('abstract class ${prefix}SerializerMixin {');

      // write fields
      fields.forEach((name, field) {
        buffer.writeln('  ${field.type.name} get $name;');
      });

      // write toJson method
      buffer.writeln('  Map<String, dynamic> toJson() => <String, dynamic>{');

      var pairs = <String>[];
      fields.forEach((name, field) {
        pairs.add("'$name': ${_fieldToJsonMapValue(name, field)}");
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

void _writeFactory(StringBuffer buffer, ClassElement classElement,
    Map<String, FieldElement> fields, String prefix) {
  // creating a copy so it can be mutated
  var fieldsToSet = new Map<String, FieldElement>.from(fields);
  var className = classElement.displayName;
  // Create the factory method

  // Get the default constructor
  // TODO: allow overriding the ctor used for the factory
  var ctor = classElement.constructors.singleWhere((ce) => ce.name == '');

  var ctorArguments = <String>[];
  var ctorNamedArguments = <String>[];

  for (var arg in ctor.parameters) {
    var field = fields[arg.name];

    if (field == null) {
      if (arg.parameterKind == ParameterKind.REQUIRED) {
        throw 'Cannot populate the required constructor argument: ${arg.displayName}.';
      }
      continue;
    }

    // TODO: validate that the types match!
    if (arg.parameterKind == ParameterKind.NAMED) {
      ctorNamedArguments.add(arg.name);
    } else {
      ctorArguments.add(arg.name);
    }
    fieldsToSet.remove(arg.name);
  }

  var finalFields = fieldsToSet.values.where((field) => field.isFinal).toSet();

  if (finalFields.isNotEmpty) {
    throw new InvalidGenerationSourceError(
        'Generator cannot target `$className`.',
        todo: 'Make the following fields writable or add them to the '
        'constructor with matching names: '
        '${finalFields.map((field) => field.name).join(', ')}.');
  }

  //
  // Generate the static factory method
  //
  buffer.writeln();
  buffer.writeln('$className ${prefix}FromJson(Map json) =>');
  buffer.write('    new $className(');
  buffer.writeAll(
      ctorArguments.map((name) => _jsonMapAccessToField(name, fields[name])),
      ', ');
  if (ctorArguments.isNotEmpty && ctorNamedArguments.isNotEmpty) {
    buffer.write(', ');
  }
  buffer.writeAll(ctorNamedArguments
          .map((name) => '$name: ' + _jsonMapAccessToField(name, fields[name])),
      ', ');

  buffer.write(')');
  if (fieldsToSet.isEmpty) {
    buffer.writeln(';');
  } else {
    fieldsToSet.forEach((name, field) {
      buffer.writeln();
      buffer.write("      ..${name} = ");
      buffer.write(_jsonMapAccessToField(name, field));
    });
    buffer.writeln(';');
  }
  buffer.writeln();
}

String _fieldToJsonMapValue(String name, FieldElement field) {
  var result = name;

  if (_isDartDateTime(field.type)) {
    return "$name == null ? null : ${name}.toIso8601String()";
  }

  return result;
}

String _jsonMapAccessToField(String name, FieldElement field) {
  var result = "json['$name']";

  if (_isDartDateTime(field.type)) {
    // TODO: this does not take into account that dart:core could be
    // imported with another name
    return "json['$name'] == null ? null : DateTime.parse($result)";
  }

  return result;
}

bool _isDartDateTime(DartType type) {
  return type.element.library != null &&
      type.element.library.isDartCore &&
      type.name == 'DateTime';
}
