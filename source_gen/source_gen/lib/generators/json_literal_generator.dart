library source_gen.example.json_literal_generator;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
//import 'package:source_gen/src/utils.dart';

import 'json_literal.dart';

class JsonLiteralGenerator extends GeneratorForAnnotation<JsonLiteral> {
  const JsonLiteralGenerator();

  Future<String> generateForAnnotatedElement(
      Element element, JsonLiteral annotation) async {
    if (p.isAbsolute(annotation.path)) {
      throw 'must be relative path to the source file';
    }

    var source = element.source as FileBasedSource;
    var sourcePath = source.file.getAbsolutePath();

    var sourcePathDir = p.dirname(sourcePath);

    var filePath = p.join(sourcePathDir, annotation.path);

    if (!await FileSystemEntity.isFile(filePath)) {
      throw 'Not a file! - $filePath';
    }

    var file = new File(filePath);
    var content = await JSON.decode(await file.readAsString());

    var thing = JSON.encode(content);

    var marked = _isConstType(content) ? 'const' : 'final';

    return '$marked _\$${element.displayName}JsonLiteral = $thing;';
  }
}

bool _isConstType(value) {
  return value == null || value is String || value is num || value is bool;
}
