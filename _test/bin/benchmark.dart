import 'dart:io';

import '../test/common/utils.dart';

Future<void> main() async {
  // only works in test
  inTest = false;
  ensureCleanGitClient();
  print('Initial build.');
  await runBuild();
  print('Done.');

  print('Files,Build time/ms,Incremental time/ms');
  for (final size in [
    100,
    500,
    1000,
    1500,
    2000,
    2500,
    3000,
    3500,
    4000,
    4500,
    5000,
  ]) {
    stdout.write('$size,');

    await createFile(
      'lib/bv_app.dart',
      [
        for (var i = 0; i != size; ++i) "import 'built_value${i + 1}.dart';",
      ].join('\n'),
    );

    for (var i = 0; i != size; ++i) {
      await createFile('lib/built_value${i + 1}.dart', '''
import 'package:built_value/built_value.dart';

import 'bv_app.dart';

part 'built_value${i + 1}.g.dart';

abstract class Value implements Built<Value, ValueBuilder> {
  Value._();
  factory Value([void Function(ValueBuilder)? updates]) = _\$Value;
}
''');
    }
    final stopwatch = Stopwatch()..start();
    await runBuild();
    stdout.write('${stopwatch.elapsedMilliseconds},');

    await createFile('lib/built_value1.dart', '''
import 'package:built_value/built_value.dart';

import 'bv_app.dart';

part 'built_value1.g.dart';

abstract class Value implements Built<Value, ValueBuilder> {
  int get x;
  Value._();
  factory Value([void Function(ValueBuilder)? updates]) = _\$Value;
}
''');
    stopwatch.reset();
    await runBuild();
    print(stopwatch.elapsedMilliseconds);
  }
}
