library source_gen.build_helper;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'src/generator.dart';
import 'src/build_file_generator.dart';

void build(List<String> args, List<Generator> generators) {
  var projPath = p.dirname(p.fromUri(Platform.script));

  var parser = _getParser();

  var result = parser.parse(args);

  var changed = result['changed'] as List;

  changed.removeWhere((changed) => changed.endsWith('.g.dart'));

  if (changed.isEmpty) {
    print('nothing changed!');
    return;
  }

  // TODO: remove this override - only for development
  changed = ['example/person.dart'];

  if (changed.isNotEmpty) {
    generate(projPath, changed.first, generators).then((foo) {
      print(foo);
    });
  }
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed', allowMultiple: true)
  ..addFlag('full', defaultsTo: false)
  ..addFlag('clean', defaultsTo: false)
  ..addOption('removed', allowMultiple: true);
