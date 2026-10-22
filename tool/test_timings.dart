// DO NOT MERGE: summarizes a `dart test --file-reporter json:FILE` report to
// find what is slow on CI.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final suites = <int, String>{};
  final tests = <int, ({String name, int suite, int start})>{};
  final durations = <({String suite, String name, int ms, String result})>[];
  var endTime = 0;
  final perSuite = <String, Map<String, int>>{};
  void add(String suite, String key, int value) {
    final m = perSuite.putIfAbsent(suite, () => {});
    m[key] = (m[key] ?? 0) + value;
  }

  final runMs = RegExp(r' run ([0-9]+)ms ');
  final compileS = RegExp(r'([0-9]+)s compiling builders');
  final builtS = RegExp(r'Built with build_runner/\w+ in ([0-9]+)s');
  final killMs = RegExp(r' kill exit_after=([0-9]+)ms total=([0-9]+)ms');
  final deleteMs = RegExp(r' delete_temp ([0-9]+)ms');
  for (final line in File(args.single).readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    final event = jsonDecode(line) as Map<String, Object?>;
    final time = event['time'] as int? ?? 0;
    if (time > endTime) endTime = time;
    if (event['type'] == 'print') {
      final message = event['message'] as String;
      if (!message.startsWith('WTIMING ')) continue;
      final suite = message.split(' ')[1];
      final run = runMs.firstMatch(message);
      if (run != null) {
        add(suite, 'runs', 1);
        add(suite, 'run_ms', int.parse(run.group(1)!));
      }
      for (final m in compileS.allMatches(message)) {
        add(suite, 'compiles', 1);
        add(suite, 'compile_s', int.parse(m.group(1)!));
      }
      for (final m in builtS.allMatches(message)) {
        add(suite, 'builds', 1);
        add(suite, 'built_s', int.parse(m.group(1)!));
      }
      final kill = killMs.firstMatch(message);
      if (kill != null) {
        add(suite, 'kills', 1);
        add(suite, 'kill_exit_ms', int.parse(kill.group(1)!));
        add(suite, 'kill_total_ms', int.parse(kill.group(2)!));
      }
      final delete = deleteMs.firstMatch(message);
      if (delete != null) add(suite, 'delete_ms', int.parse(delete.group(1)!));
      continue;
    }
    switch (event['type']) {
      case 'suite':
        final suite = event['suite'] as Map<String, Object?>;
        final path = (suite['path'] as String? ?? '?').replaceAll(r'\', '/');
        suites[suite['id'] as int] = path.substring(path.lastIndexOf('/') + 1);
      case 'testStart':
        final test = event['test'] as Map<String, Object?>;
        tests[test['id'] as int] = (
          name: test['name'] as String,
          suite: test['suiteID'] as int,
          start: time,
        );
      case 'testDone':
        final test = tests[event['testID'] as int]!;
        durations.add((
          suite: suites[test.suite] ?? '?',
          name: test.name,
          ms: time - test.start,
          result: event['result'] as String,
        ));
    }
  }
  durations.sort((a, b) => b.ms.compareTo(a.ms));
  stdout.writeln('TEST_TIMINGS total=${endTime}ms tests=${durations.length}');
  for (final d in durations) {
    stdout.writeln('TEST_TIMING ${d.ms}ms ${d.result} ${d.suite}: ${d.name}');
  }
  final totals = <String, int>{};
  for (final MapEntry(key: suite, value: m) in perSuite.entries) {
    stdout.writeln(
      'SUITE_TIMING $suite '
      '${[for (final e in m.entries) '${e.key}=${e.value}'].join(' ')}',
    );
    for (final e in m.entries) {
      totals[e.key] = (totals[e.key] ?? 0) + e.value;
    }
  }
  stdout.writeln(
    'SUITE_TIMING TOTAL '
    '${[for (final e in totals.entries) '${e.key}=${e.value}'].join(' ')}',
  );
}
