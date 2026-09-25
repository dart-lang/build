/// Rewrites the value producing exits of a function so that checks run with the
/// returned value in scope under the name `result`.
///
/// The rewrite depends on how the value reaches the caller: directly, as a
/// future awaited in an `async` body, or as a future returned without `async`.
/// Each form must name the value type, otherwise the returned expression loses
/// its context type, inference falls back to `Object?` and the generated code
/// does not compile.
class ExitRewriter {
  ExitRewriter({required this.returnType, required this.isAsync});

  /// The source text of the declared return type, or `null` if there is none.
  final String? returnType;

  final bool isAsync;

  /// A statement that evaluates [expression], runs [checks] with the value
  /// bound to `result`, then returns the value.
  String returnValue(String expression, String checks) {
    if (isAsync) {
      final valueType = _futureTypeArgument(returnType);
      final constructor = valueType == null
          ? 'Future.value'
          : 'Future<$valueType>.value';
      return 'return await ($constructor($expression)'
          '.then((${_parameterType(valueType)}result) {\n'
          '$checks'
          'return result;\n'
          '}));';
    }
    if (_isFutureType(returnType)) {
      final valueType = _futureTypeArgument(returnType);
      return 'return ($expression)'
          '.then((${_parameterType(valueType)}result) {\n'
          '$checks'
          'return result;\n'
          '});';
    }
    return 'return ((${_parameterType(_syncValueType)}result) {\n'
        '$checks'
        'return result;\n'
        '})($expression);';
  }

  /// The declared return type, or `null` if it carries no information that
  /// inference can use.
  String? get _syncValueType {
    final type = returnType;
    if (type == null || type == 'void' || type == 'dynamic') return null;
    return type;
  }

  static String _parameterType(String? valueType) =>
      valueType == null ? '' : '$valueType ';

  static bool _isFutureType(String? typeStr) {
    if (typeStr == null) return false;
    final trimmed = typeStr.trim();
    if (trimmed == 'FutureOr' || trimmed.startsWith('FutureOr<')) return false;
    return trimmed == 'Future' ||
        trimmed.startsWith('Future<') ||
        trimmed.endsWith('.Future') ||
        trimmed.contains('.Future<');
  }

  /// The `X` in `Future<X>` or `FutureOr<X>`, or `null` if [typeStr] is not
  /// such a type or has no type argument.
  ///
  /// Matches the outermost angle brackets so nested generics are preserved.
  static String? _futureTypeArgument(String? typeStr) {
    if (typeStr == null) return null;
    final trimmed = typeStr.trim();
    final open = trimmed.indexOf('<');
    if (open == -1 || !trimmed.endsWith('>')) return null;
    final name = trimmed.substring(0, open);
    if (name != 'Future' &&
        name != 'FutureOr' &&
        !name.endsWith('.Future') &&
        !name.endsWith('.FutureOr')) {
      return null;
    }
    final argument = trimmed.substring(open + 1, trimmed.length - 1).trim();
    if (argument.isEmpty) return null;
    // Reject anything that is not a single type argument.
    var depth = 0;
    for (final rune in argument.runes) {
      final char = String.fromCharCode(rune);
      if (char == '<') ++depth;
      if (char == '>') --depth;
      if (char == ',' && depth == 0) return null;
    }
    if (depth != 0) return null;
    if (argument == 'void' || argument == 'dynamic') return null;
    return argument;
  }
}
