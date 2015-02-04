library source_gen.test.project_generator_test;

import 'dart:async';
import 'dart:io';

import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:path/path.dart' as p;

import 'package:source_gen/src/build_file_generator.dart';
import 'package:source_gen/json_serial/json_generator.dart';

import 'test_utils.dart';

void main() {
  test('Simple test of JsonGenerator', () {
    String projectPath;

    schedule(() async {
      var dir = await _createTempDir();

      d.defaultRoot = dir.path;

      projectPath = await _createPackageStub('pkg');
    });

    schedule(() async {
      var filePath = p.join(projectPath, 'lib', 'person.dart');
      var output =
          await generate(getPackagePath(), filePath, [const JsonGenerator()]);

      expect(output, isNotNull);
      expect(output, isNotEmpty);
    });

    schedule(() async {
      d
          .dir('pkg', [
        d.dir('lib', [
          d.file('person.dart', _personContent),
          d.matcherFile('person.g.dart', isNotEmpty)
        ])
      ])
          .validate();
    });
  });
}

/// Creates a package using [pkgName] an the current [d.defaultRoot].
Future<String> _createPackageStub(String pkgName) async {
  await d
      .dir(pkgName, [d.dir('lib', [d.file('person.dart', _personContent)])])
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

const _personContent = r'''library source_gen.example.person;

import 'package:source_gen/json_serial/json_annotation.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();
}
''';
