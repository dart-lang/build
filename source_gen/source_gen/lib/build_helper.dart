library dart_source_gen.build_helper;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'dart_source_gen.dart';
import 'generator.dart';

void build(List<String> args, List<Generator> generators) {
  var projPath = p.dirname(p.fromUri(Platform.script));

  var parser = _getParser();

  var result = parser.parse(args);

  var changed = result['changed'] as String;

  // TODO override for dev
  changed = 'example/person.dart';

  if (changed != null) {
    generate(projPath, changed, generators).then((foo) {
      print(foo);
    });
  }
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('machine')
  ..addOption('changed')
  ..addFlag('full')
  ..addFlag('clean')
  ..addOption('removed');
