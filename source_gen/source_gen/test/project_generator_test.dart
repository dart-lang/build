library source_gen.test.project_generator_test;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:source_gen/src/build_file_generator.dart';
import 'package:source_gen/src/generator.dart';

import 'test_utils.dart';

void main() {
  test('Simple Generator test', () {
    String projectPath;

    schedule(() async {
      var dir = await _createTempDir();

      d.defaultRoot = dir.path;

      projectPath = await _createPackageStub('pkg');
    });

    schedule(() async {
      var filePath = p.join(projectPath, 'lib', 'person.dart');
      var output =
          await generate(getPackagePath(), filePath, [const _TestGenerator()]);

      expect(output, isNotNull);
      expect(output, isNotEmpty);
    });

    schedule(() async {
      d
          .dir('pkg', [
        d.dir('lib', [
          d.file('person.dart', _testLibContent),
          d.matcherFile('person.g.dart', contains(_testGenPartContent))
        ])
      ])
          .validate();
    });
  });
}

/// Creates a package using [pkgName] an the current [d.defaultRoot].
Future<String> _createPackageStub(String pkgName) async {
  await d
      .dir(pkgName, [d.dir('lib', [d.file('person.dart', _testLibContent)])])
      .create();

  var pkgPath = p.join(d.defaultRoot, pkgName);
  var exists = await FileSystemEntity.isDirectory(pkgPath);

  assert(exists);

  return pkgPath;
}

Future<Directory> _createTempDir([bool scheduleDelete = true]) async {
  var ticks = new DateTime.now().toUtc().millisecondsSinceEpoch;
  var dir = await Directory.systemTemp.createTemp('source_gen.test.$ticks.');

  currentSchedule.onComplete.schedule(() {
    if (scheduleDelete) {
      return dir.delete(recursive: true);
    } else {
      print('Not deleting $dir');
    }
  });

  return dir;
}

class _TestGenerator extends Generator {
  const _TestGenerator();

  String generate(Element element) {
    return '// Code for $element';
  }

  String toString() => 'TestGenerator';
}

const _testLibContent = r'''library test_lib;
final int foo = 42;

class Person extends Object with _$PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();
}
''';

const _testGenPartContent = r'''part of test_lib;

// **************************************************************************
// Generator: TestGenerator
// Target: final int foo
// **************************************************************************

// Code for int foo

// **************************************************************************
// Generator: TestGenerator
// Target: class Person
// **************************************************************************

// Code for Person
''';
