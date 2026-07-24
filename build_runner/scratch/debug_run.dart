import 'dart:io';

Future<void> main() async {
  final result = await Process.run('dart', [
    'run',
    'test/integration_tests/output_strategy_test.dart',
  ]);
  print('Exit code: ${result.exitCode}');
  print('STDOUT:\n${result.stdout}');
  print('STDERR:\n${result.stderr}');
}
