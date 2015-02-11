library source_gen.build_helper;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'src/io.dart';
import 'src/generate.dart';
import 'src/generator.dart';

void build(List<String> args, List<Generator> generators,
    {List<String> librarySearchPaths}) {
  var projPath = p.dirname(p.fromUri(Platform.script));

  var parser = _getParser();

  var result = parser.parse(args);

  var changed = result['changed'] as List<String>;

  changed.removeWhere(isGeneratedFile);

  if (changed.isEmpty) {
    print('nothing changed!');
    return;
  }

  if (changed.isNotEmpty) {
    generate(projPath, changed, generators,
        librarySearchPaths: librarySearchPaths).then((message) {
      print(message);
    });
  }
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed', allowMultiple: true)
  ..addFlag('full', defaultsTo: false)
  ..addFlag('clean', defaultsTo: false)
  ..addOption('removed', allowMultiple: true);
