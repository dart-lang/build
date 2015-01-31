library source_gen.build_helper;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'generator.dart';
import 'source_gen.dart';

void build(List<String> args, List<Generator> generators) {
  var projPath = p.dirname(p.fromUri(Platform.script));

  var parser = _getParser();

  var result = parser.parse(args);

  var changed = result['changed'] as String;

  if (changed == null) {
    print('nothing changed!');
    return;
  }

  if (changed.endsWith('.g.dart')) {
    print("skipping generated file $changed");
    return;
  }

  // TODO override for dev
  changed = 'example/person.dart';

  if (changed != null) {
    generate(projPath, changed, generators).then((foo) {
      print(foo);
    });
  }
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed')
  ..addFlag('full', defaultsTo: false)
  ..addFlag('clean', defaultsTo: false)
  ..addOption('removed');
