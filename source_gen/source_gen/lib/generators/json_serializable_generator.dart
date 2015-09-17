// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
      var friendlyName = friendlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JsonSerializable annotation from `$friendlyName`.');
    }

    var classElement = element as ClassElement;
    var className = classElement.name;

    // Get all of the fields that need to be assigned
    // TODO: support overriding the field set with an annotation option
    var fields =
        classElement.fields.fold(<String, FieldElement>{}, (map, field) {
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
        pairs.add("'$name': ${_fieldToJsonMapValue(name, field.type)}");
      });
      buffer.writeln(pairs.join(','));

      buffer.writeln('  };');

      buffer.write('}');
    }

    return buffer.toString();
  }
}

void _writeFactory(StringBuffer buffer, ClassElement classElement,
    Map<String, FieldElement> fields, String prefix) {
  // creating a copy so it can be mutated
  var fieldsToSet = new Map<String, FieldElement>.from(fields);
  var className = classElement.displayName;
  // Create the factory method

  // Get the default constructor
  // TODO: allow overriding the ctor used for the factory
  var ctor = classElement.unnamedConstructor;

  var ctorArguments = <ParameterElement>[];
  var ctorNamedArguments = <ParameterElement>[];

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
      ctorNamedArguments.add(arg);
    } else {
      ctorArguments.add(arg);
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
      ctorArguments.map((paramElement) => _jsonMapAccessToField(
          paramElement.name, fields[paramElement.name], paramElement)),
      ', ');
  if (ctorArguments.isNotEmpty && ctorNamedArguments.isNotEmpty) {
    buffer.write(', ');
  }
  buffer.writeAll(
      ctorNamedArguments.map((paramElement) => '${paramElement.name}: ' +
          _jsonMapAccessToField(
              paramElement.name, fields[paramElement.name], paramElement)),
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

String _fieldToJsonMapValue(String name, DartType fieldType, [int depth = 0]) {
  if (_hasFromJsonCtor(fieldType)) {
    return name;
  }

  if (_implementsDartList(fieldType)) {
    var indexVal = "i${depth}";

    var substitute = '${name}[$indexVal]';
    var subFieldValue = _fieldToJsonMapValue(
        substitute, _getIterableGenericType(fieldType), depth + 1);
    if (subFieldValue != substitute) {
      // TODO: the type could be imported from a library with a prefix!
      return "${name} == null ? null : new List.generate(${name}.length, (int $indexVal) => $subFieldValue)";
    }
  }

  if (_isDartDateTime(fieldType)) {
    return "$name?.toIso8601String()";
  }

  return name;
}

String _jsonMapAccessToField(String name, FieldElement field,
    [ParameterElement ctorParam]) {
  var result = "json['$name']";
  return _writeAccessToVar(result, field.type, ctorParam: ctorParam);
}

String _writeAccessToVar(String varExpression, DartType searchType,
    {ParameterElement ctorParam, int depth: 0}) {
  if (ctorParam != null) {
    searchType = ctorParam.type;
  }

  if (_isDartDateTime(searchType)) {
    // TODO: this does not take into account that dart:core could be
    // imported with another name
    return "$varExpression == null ? null : DateTime.parse($varExpression)";
  }

  if (_hasFromJsonCtor(searchType)) {
    // TODO: the type could be imported from a library with a prefix!
    return "$varExpression == null ? null : new ${searchType.name}.fromJson($varExpression)";
  }

  if (_isDartIterable(searchType) || _isDartList(searchType)) {
    var iterableGenericType = _getIterableGenericType(searchType);

    var itemVal = "v$depth";

    var output = "$varExpression?.map(($itemVal) =>"
        "${_writeAccessToVar(itemVal, iterableGenericType, depth: depth+1)}"
        ")";

    if (_isDartList(searchType)) {
      output += ".toList()";
    }

    return output;
  }

  return varExpression;
}

bool _hasFromJsonCtor(DartType type) {
  if (type is! InterfaceType) return false;

  var classElement = type.element as ClassElement;

  for (var ctor in classElement.constructors) {
    if (ctor.name == 'fromJson') {
      // TODO: validate that there are the right number and type of arguments
      return true;
    }
  }

  return false;
}

DartType _getIterableGenericType(InterfaceTypeImpl type) {
  var iterableThing = _typeTest(type, _isDartIterable);

  return iterableThing.typeArguments.single;
}

bool _implementsDartList(DartType type) => _typeTest(type, _isDartList) != null;

DartType _typeTest(DartType type, bool tester(DartType)) {
  if (tester(type)) return type;

  if (type is InterfaceType) {
    var items = type.interfaces.where(tester).toList();

    if (items.length > 1) {
      throw 'weird - more than 1 interface matches the type test - $items';
    }

    if (items.length == 1) {
      return items.single;
    }

    if (type.superclass != null) {
      return _typeTest(type.superclass, tester);
    }
  }
  return null;
}

bool _isDartIterable(DartType type) {
  return type.element.library != null &&
      type.element.library.isDartCore &&
      type.name == 'Iterable';
}

bool _isDartList(DartType type) {
  return type.element.library != null &&
      type.element.library.isDartCore &&
      type.name == 'List';
}

bool _isDartDateTime(DartType type) {
  return type.element.library != null &&
      type.element.library.isDartCore &&
      type.name == 'DateTime';
}
