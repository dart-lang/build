import 'dart:io';

class Pre {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;
  final String? c10;

  const Pre(
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
    this.c10,
  ]);
}

class Post {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;
  final String? c10;

  const Post(
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
    this.c10,
  ]);
}

class Invariant {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;
  final String? c10;

  const Invariant(
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
    this.c10,
  ]);
}

class Trace {
  final String? message;

  const Trace([this.message]);
}

class Contracts {
  static bool enabled =
      Platform.environment['DART_CONTRACTS_ENABLED'] == 'true';

  static const int maxTraceHistory = 50;
  static final List<String> _traceHistory = [];

  static void recordTrace(String entry) {
    if (_traceHistory.length >= maxTraceHistory) {
      _traceHistory.removeAt(0);
    }
    _traceHistory.add(entry);
  }

  static List<String> get traceHistory => List.unmodifiable(_traceHistory);

  static void clearTraceHistory() {
    _traceHistory.clear();
  }
}

class ContractViolation implements Exception {
  final String message;
  final List<String> recentTraces;

  ContractViolation(this.message, [List<String>? recentTraces])
    : recentTraces = recentTraces ?? Contracts.traceHistory;

  @override
  String toString() {
    if (recentTraces.isEmpty) {
      return 'ContractViolation: $message';
    }
    final buffer = StringBuffer('ContractViolation: $message\nRecent trace:\n');
    for (final t in recentTraces) {
      buffer.writeln('  $t');
    }
    return buffer.toString().trimRight();
  }
}
