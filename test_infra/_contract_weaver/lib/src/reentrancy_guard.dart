/// Wraps generated checks so that they do not check each other.
///
/// A clause is arbitrary Dart, so evaluating it can call contracted code.
/// Setting `Contracts.checking` for the duration turns every check reached
/// that way into a no-op.
class ReentrancyGuard {
  /// [checks] wrapped so that it runs only outside another check, and marks
  /// that a check is running while it runs.
  ///
  /// [when] is an additional condition for running [checks].
  static String wrap(String checks, {String? when}) {
    final condition = when == null
        ? '!Contracts.checking'
        : '!Contracts.checking && $when';
    return 'if ($condition) {\n'
        'Contracts.checking = true;\n'
        'try {\n'
        '$checks'
        '} finally {\n'
        'Contracts.checking = false;\n'
        '}\n'
        '}\n';
  }
}
