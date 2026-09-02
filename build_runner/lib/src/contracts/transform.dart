import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_style/dart_style.dart';

/// Transforms Dart source code to embed executable checks for
/// `@Pre`, `@Post`, and `@Invariant` contracts.
String transformContracts(String source) {
  final parseResult = parseString(content: source, throwIfDiagnostics: false);
  if (parseResult.errors.isNotEmpty) {
    final messages = parseResult.errors.map((e) => e.message).join('\n');
    throw FormatException('Source has parse errors:\n$messages');
  }
  final unit = parseResult.unit;

  final collector = _ContractTransformCollector(source);
  unit.accept(collector);

  if (collector.isEmpty) return source;

  final transformed = collector.applyReplacements();
  try {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(transformed);
  } catch (e) {
    throw FormatException(
      'Failed to format transformed contracts code: $e\n'
      'Transformed code was:\n$transformed',
    );
  }
}

/// Transforms [file] in place if it contains contracts.
Future<bool> transformFile(File file) async {
  final content = await file.readAsString();
  final transformed = transformContracts(content);
  if (transformed != content) {
    await file.writeAsString(transformed);
    return true;
  }
  return false;
}

/// Recursively transforms all `.dart` files in [dir] in place.
Future<int> transformDirectory(Directory dir) async {
  var count = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (await transformFile(entity)) {
        count++;
      }
    }
  }
  return count;
}

class _Replacement {
  final int offset;
  final int length;
  final String text;

  _Replacement(this.offset, this.length, this.text);
}

class _ContractTransformCollector extends RecursiveAstVisitor<void> {
  final String source;
  final List<_Replacement> _replacements = [];

  _ContractTransformCollector(this.source);

  bool get isEmpty => _replacements.isEmpty;

  bool _isFutureType(String? typeStr) {
    if (typeStr == null) return false;
    final trimmed = typeStr.trim();
    if (trimmed == 'FutureOr' || trimmed.startsWith('FutureOr<')) return false;
    return trimmed == 'Future' ||
        trimmed.startsWith('Future<') ||
        trimmed.endsWith('.Future') ||
        trimmed.contains('.Future<');
  }

  String applyReplacements() {
    // Sort descending by offset. If offsets are equal, preserve order.
    _replacements.sort((a, b) => b.offset.compareTo(a.offset));

    var result = source;
    for (final r in _replacements) {
      result =
          result.substring(0, r.offset) +
          r.text +
          result.substring(r.offset + r.length);
    }
    return result;
  }

  List<String> _extractClauses(NodeList<Annotation> metadata, String name) {
    final clauses = <String>[];
    for (final annotation in metadata) {
      if (annotation.name.name != name) continue;
      final args = annotation.arguments?.arguments;
      if (args == null || args.isEmpty) {
        throw FormatException(
          '@$name annotation requires at least one contract expression string.',
        );
      }
      for (final arg in args) {
        if (arg is SimpleStringLiteral) {
          clauses.add(arg.value);
        } else if (arg is StringLiteral) {
          final val = arg.stringValue;
          if (val != null) {
            clauses.add(val);
          } else {
            throw FormatException(
              '@$name contract expression must be a non-empty string literal.',
            );
          }
        } else {
          final argText = source.substring(arg.offset, arg.end);
          throw FormatException(
            '@$name contract expression must be a string literal, '
            'got: $argText',
          );
        }
      }
    }
    return clauses;
  }

  String _buildPreCheck(List<String> clauses) {
    final buffer = StringBuffer();
    buffer.writeln('if (Contracts.enabled) {');
    buffer.writeln('  Contracts.enabled = false;');
    buffer.writeln('  try {');
    for (final c in clauses) {
      buffer.writeln(
        "    if (!($c)) throw ContractViolation('Precondition failed: $c');",
      );
    }
    buffer.writeln('  } finally {');
    buffer.writeln('    Contracts.enabled = true;');
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _buildPostCheck(List<String> clauses) {
    final buffer = StringBuffer();
    buffer.writeln('if (Contracts.enabled) {');
    buffer.writeln('  Contracts.enabled = false;');
    buffer.writeln('  try {');
    for (final c in clauses) {
      buffer.writeln(
        "    if (!($c)) throw ContractViolation('Postcondition failed: $c');",
      );
    }
    buffer.writeln('  } finally {');
    buffer.writeln('    Contracts.enabled = true;');
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _buildInvariantMethod(List<String> clauses) {
    final buffer = StringBuffer();
    buffer.writeln('void _checkInvariants() {');
    buffer.writeln('  if (Contracts.enabled) {');
    buffer.writeln('    Contracts.enabled = false;');
    buffer.writeln('    try {');
    for (final c in clauses) {
      buffer.writeln(
        "      if (!($c)) throw ContractViolation('Invariant failed: $c');",
      );
    }
    buffer.writeln('    } finally {');
    buffer.writeln('      Contracts.enabled = true;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  String? _currentClassName;

  bool _hasTrace(NodeList<Annotation> metadata) {
    return metadata.any((a) => a.name.name == 'Trace');
  }

  String? _extractTraceMessage(NodeList<Annotation> metadata) {
    for (final a in metadata) {
      if (a.name.name != 'Trace') continue;
      final args = a.arguments?.arguments;
      if (args != null && args.isNotEmpty) {
        final arg = args.first;
        final raw = source.substring(arg.offset, arg.end);
        if ((raw.startsWith("'") && raw.endsWith("'")) ||
            (raw.startsWith('"') && raw.endsWith('"'))) {
          final unquoted = raw.substring(1, raw.length - 1);
          // Unescape backslash dollar so that the generated string performs
          // runtime interpolation inside the method body.
          return unquoted.replaceAll(r'\$', r'$');
        }
        return '\$($raw)';
      }
    }
    return null;
  }

  String _buildTraceEntry(
    String qualifiedName,
    String? customMessage,
    FormalParameterList? parameters,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('if (Contracts.enabled) {');
    buffer.writeln('  Contracts.enabled = false;');
    buffer.writeln('  try {');
    if (customMessage != null) {
      buffer.writeln("    Contracts.recordTrace('>> $customMessage');");
    } else {
      final paramParts = <String>[];
      if (parameters != null) {
        for (final p in parameters.parameters) {
          final name = p.name?.lexeme;
          if (name != null) {
            paramParts.add('$name: \$$name');
          }
        }
      }
      final paramsStr = paramParts.join(', ');
      buffer.writeln(
        "    Contracts.recordTrace('>> $qualifiedName($paramsStr)');",
      );
    }
    buffer.writeln('  } finally {');
    buffer.writeln('    Contracts.enabled = true;');
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _buildTraceExit(String qualifiedName, bool isVoid) {
    final buffer = StringBuffer();
    buffer.writeln('if (Contracts.enabled) {');
    buffer.writeln('  Contracts.enabled = false;');
    buffer.writeln('  try {');
    if (isVoid) {
      buffer.writeln("    Contracts.recordTrace('<< $qualifiedName');");
    } else {
      buffer.writeln(
        "    Contracts.recordTrace('<< $qualifiedName -> \$result');",
      );
    }
    buffer.writeln('  } finally {');
    buffer.writeln('    Contracts.enabled = true;');
    buffer.writeln('  }');
    buffer.writeln('}');
    return buffer.toString();
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final previousClassName = _currentClassName;
    _currentClassName = node.namePart.typeName.lexeme;

    final invariantClauses = _extractClauses(node.metadata, 'Invariant');
    final hasInvariant = invariantClauses.isNotEmpty;

    if (hasInvariant) {
      // Inject _checkInvariants method before right bracket of class.
      _replacements.add(
        _Replacement(
          body.rightBracket.offset,
          0,
          '\n${_buildInvariantMethod(invariantClauses)}\n',
        ),
      );
    }

    try {
      for (final member in body.members) {
        if (member is ConstructorDeclaration) {
          _transformConstructor(member, hasInvariant);
        } else if (member is MethodDeclaration) {
          _transformMethod(member, hasInvariant);
        }
      }
    } finally {
      _currentClassName = previousClassName;
    }
  }

  void _transformConstructor(
    ConstructorDeclaration node,
    bool classHasInvariant,
  ) {
    if (node.redirectedConstructor != null) return;
    if (node.constKeyword != null) return;

    if (node.factoryKeyword != null) {
      final preClauses = _extractClauses(node.metadata, 'Pre');
      final postClauses = _extractClauses(node.metadata, 'Post');
      if (preClauses.isEmpty && postClauses.isEmpty) return;

      final body = node.body;
      final returnTypePrefix = _currentClassName != null
          ? '$_currentClassName '
          : '';
      if (body is ExpressionFunctionBody) {
        final exprSource = source.substring(
          body.expression.offset,
          body.expression.end,
        );
        final buffer = StringBuffer('{\n');
        if (preClauses.isNotEmpty) buffer.write(_buildPreCheck(preClauses));

        if (postClauses.isNotEmpty) {
          buffer.writeln('return (($returnTypePrefix result) {');
          buffer.write(_buildPostCheck(postClauses));
          buffer.writeln('return result;');
          buffer.writeln('})($exprSource);');
        } else {
          buffer.writeln('return $exprSource;');
        }
        buffer.write('}');

        final startOffset = body.functionDefinition.offset;
        final length = body.end - startOffset;
        _replacements.add(_Replacement(startOffset, length, buffer.toString()));
      } else if (body is BlockFunctionBody) {
        if (preClauses.isNotEmpty) {
          _replacements.add(
            _Replacement(
              body.block.leftBracket.end,
              0,
              '\n${_buildPreCheck(preClauses)}\n',
            ),
          );
        }
        if (postClauses.isNotEmpty) {
          _transformBlockReturns(
            body.block,
            postClauses,
            false,
            false,
            false,
            _currentClassName,
            null,
          );
        }
      }
      return;
    }

    if (node.initializers.any((i) => i is RedirectingConstructorInvocation)) {
      return;
    }

    final preClauses = _extractClauses(node.metadata, 'Pre');
    final postClauses = _extractClauses(node.metadata, 'Post');
    final hasPre = preClauses.isNotEmpty;
    final hasPost = postClauses.isNotEmpty;
    if (!hasPre && !hasPost && !classHasInvariant) return;

    final body = node.body;
    if (body is EmptyFunctionBody) {
      final buffer = StringBuffer('{\n');
      if (hasPre) buffer.write(_buildPreCheck(preClauses));
      if (classHasInvariant) buffer.writeln('_checkInvariants();');
      if (hasPost) buffer.write(_buildPostCheck(postClauses));
      buffer.write('}');
      _replacements.add(
        _Replacement(
          body.semicolon.offset,
          body.semicolon.length,
          buffer.toString(),
        ),
      );
    } else if (body is BlockFunctionBody) {
      if (hasPre) {
        _replacements.add(
          _Replacement(
            body.block.leftBracket.end,
            0,
            '\n${_buildPreCheck(preClauses)}\n',
          ),
        );
      }
      if (classHasInvariant || hasPost) {
        final collector = _ReturnStatementCollector();
        body.block.accept(collector);
        for (final ret in collector.returns) {
          final retBuffer = StringBuffer('{\n');
          if (classHasInvariant) retBuffer.writeln('_checkInvariants();');
          if (hasPost) retBuffer.write(_buildPostCheck(postClauses));
          retBuffer.writeln('return;');
          retBuffer.write('}');
          _replacements.add(
            _Replacement(ret.offset, ret.length, retBuffer.toString()),
          );
        }

        final lastStatement = body.block.statements.isNotEmpty
            ? body.block.statements.last
            : null;
        if (lastStatement is! ReturnStatement) {
          final exitBuffer = StringBuffer('\n');
          if (classHasInvariant) exitBuffer.writeln('_checkInvariants();');
          if (hasPost) exitBuffer.write(_buildPostCheck(postClauses));
          _replacements.add(
            _Replacement(
              body.block.rightBracket.offset,
              0,
              exitBuffer.toString(),
            ),
          );
        }
      }
    }
  }

  void _transformMethod(MethodDeclaration node, bool classHasInvariant) {
    if (node.body is EmptyFunctionBody) return;

    final preClauses = _extractClauses(node.metadata, 'Pre');
    final postClauses = _extractClauses(node.metadata, 'Post');
    final hasTrace = _hasTrace(node.metadata);
    final customTrace = _extractTraceMessage(node.metadata);
    final methodName = node.name.lexeme;
    final isExcludedFromInvariants =
        node.isGetter ||
        methodName == '==' ||
        methodName == 'hashCode' ||
        methodName == 'toString';
    final isPublicInstance =
        !node.isStatic &&
        !methodName.startsWith('_') &&
        !isExcludedFromInvariants;
    final checkInvariant = classHasInvariant && isPublicInstance;

    if (preClauses.isEmpty &&
        postClauses.isEmpty &&
        !checkInvariant &&
        !hasTrace) {
      return;
    }

    final qualifiedName = _currentClassName != null
        ? '$_currentClassName.$methodName'
        : methodName;

    final body = node.body;
    final returnTypeStr = node.returnType?.toSource();
    final isSetter = node.isSetter;
    final isVoid = isSetter || returnTypeStr == 'void';
    final isAsync = body.isAsynchronous;
    final isFuture = _isFutureType(returnTypeStr);

    if (body is ExpressionFunctionBody) {
      final exprSource = source.substring(
        body.expression.offset,
        body.expression.end,
      );

      final buffer = StringBuffer('{\n');
      if (hasTrace) {
        buffer.write(
          _buildTraceEntry(qualifiedName, customTrace, node.parameters),
        );
      }
      if (checkInvariant) buffer.writeln('_checkInvariants();');
      if (preClauses.isNotEmpty) buffer.write(_buildPreCheck(preClauses));

      if (checkInvariant) buffer.writeln('try {');

      if (postClauses.isNotEmpty || hasTrace) {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(qualifiedName, true));
        } else if (isAsync) {
          buffer.writeln(
            'return await (Future.value($exprSource).then((result) {',
          );
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(qualifiedName, false));
          buffer.writeln('return result;');
          buffer.writeln('}));');
        } else if (isFuture) {
          buffer.writeln('return ($exprSource).then((result) {');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(qualifiedName, false));
          buffer.writeln('return result;');
          buffer.writeln('});');
        } else {
          final typePrefix =
              returnTypeStr != null &&
                  returnTypeStr != 'void' &&
                  returnTypeStr != 'dynamic'
              ? '$returnTypeStr '
              : '';
          buffer.writeln('return (($typePrefix result) {');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(qualifiedName, false));
          buffer.writeln('return result;');
          buffer.writeln('})($exprSource);');
        }
      } else {
        if (isVoid) {
          buffer.writeln('$exprSource;');
        } else {
          buffer.writeln('return $exprSource;');
        }
      }

      if (checkInvariant) {
        buffer.writeln('} finally {');
        buffer.writeln('  _checkInvariants();');
        buffer.writeln('}');
      }
      buffer.write('}');

      final startOffset = body.functionDefinition.offset;
      final length = body.end - startOffset;
      _replacements.add(_Replacement(startOffset, length, buffer.toString()));
    } else if (body is BlockFunctionBody) {
      final entryBuffer = StringBuffer();
      if (hasTrace) {
        entryBuffer.write(
          _buildTraceEntry(qualifiedName, customTrace, node.parameters),
        );
      }
      if (checkInvariant) entryBuffer.writeln('_checkInvariants();');
      if (preClauses.isNotEmpty) {
        entryBuffer.write(_buildPreCheck(preClauses));
      }
      if (checkInvariant) entryBuffer.writeln('try {');

      if (entryBuffer.isNotEmpty) {
        _replacements.add(
          _Replacement(body.block.leftBracket.end, 0, '\n$entryBuffer\n'),
        );
      }

      if (postClauses.isNotEmpty || hasTrace) {
        _transformBlockReturns(
          body.block,
          postClauses,
          isVoid,
          isAsync,
          isFuture,
          returnTypeStr,
          hasTrace ? qualifiedName : null,
        );
      }

      final closingBuffer = StringBuffer('\n');
      final lastStatement = body.block.statements.isNotEmpty
          ? body.block.statements.last
          : null;
      if (isVoid && lastStatement is! ReturnStatement) {
        if (postClauses.isNotEmpty) {
          closingBuffer.write(_buildPostCheck(postClauses));
        }
        if (hasTrace) {
          closingBuffer.write(_buildTraceExit(qualifiedName, true));
        }
      }
      if (checkInvariant) {
        closingBuffer.writeln('} finally {');
        closingBuffer.writeln('  _checkInvariants();');
        closingBuffer.writeln('}');
      }
      if (closingBuffer.length > 1) {
        _replacements.add(
          _Replacement(
            body.block.rightBracket.offset,
            0,
            closingBuffer.toString(),
          ),
        );
      }
    }
  }

  void _transformBlockReturns(
    Block block,
    List<String> postClauses,
    bool isVoid,
    bool isAsync,
    bool isFuture,
    String? returnTypeStr, [
    String? traceQualifiedName,
  ]) {
    final collector = _ReturnStatementCollector();
    block.accept(collector);

    for (final statement in collector.returns) {
      final expr = statement.expression;
      if (expr != null) {
        final exprSource = source.substring(expr.offset, expr.end);
        final buffer = StringBuffer();
        if (isAsync) {
          buffer.writeln(
            'return await (Future.value($exprSource).then((result) {',
          );
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (traceQualifiedName != null) {
            buffer.write(_buildTraceExit(traceQualifiedName, false));
          }
          buffer.writeln('  return result;');
          buffer.write('}));');
        } else if (isFuture) {
          buffer.writeln('return ($exprSource).then((result) {');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (traceQualifiedName != null) {
            buffer.write(_buildTraceExit(traceQualifiedName, false));
          }
          buffer.writeln('  return result;');
          buffer.write('});');
        } else {
          final typePrefix =
              returnTypeStr != null &&
                  returnTypeStr != 'void' &&
                  returnTypeStr != 'dynamic'
              ? '$returnTypeStr '
              : '';
          buffer.write('return (($typePrefix result) {\n');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (traceQualifiedName != null) {
            buffer.write(_buildTraceExit(traceQualifiedName, false));
          }
          buffer.writeln('  return result;');
          buffer.write('})($exprSource);');
        }

        _replacements.add(
          _Replacement(statement.offset, statement.length, buffer.toString()),
        );
      } else {
        final buffer = StringBuffer('{\n');
        if (postClauses.isNotEmpty) buffer.write(_buildPostCheck(postClauses));
        if (traceQualifiedName != null) {
          buffer.write(_buildTraceExit(traceQualifiedName, true));
        }
        buffer.writeln('return;');
        buffer.write('}');

        _replacements.add(
          _Replacement(statement.offset, statement.length, buffer.toString()),
        );
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final preClauses = _extractClauses(node.metadata, 'Pre');
    final postClauses = _extractClauses(node.metadata, 'Post');
    final hasTrace = _hasTrace(node.metadata);
    final customTrace = _extractTraceMessage(node.metadata);
    if (preClauses.isEmpty && postClauses.isEmpty && !hasTrace) return;

    final functionName = node.name.lexeme;
    final body = node.functionExpression.body;
    final returnTypeStr = node.returnType?.toSource();
    final isVoid = returnTypeStr == 'void';
    final isAsync = body.isAsynchronous;
    final isFuture = _isFutureType(returnTypeStr);

    if (body is ExpressionFunctionBody) {
      final exprSource = source.substring(
        body.expression.offset,
        body.expression.end,
      );

      final buffer = StringBuffer('{\n');
      if (hasTrace) {
        buffer.write(
          _buildTraceEntry(
            functionName,
            customTrace,
            node.functionExpression.parameters,
          ),
        );
      }
      if (preClauses.isNotEmpty) buffer.write(_buildPreCheck(preClauses));

      if (postClauses.isNotEmpty || hasTrace) {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(functionName, true));
        } else if (isAsync) {
          buffer.writeln(
            'return await (Future.value($exprSource).then((result) {',
          );
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(functionName, false));
          buffer.writeln('return result;');
          buffer.writeln('}));');
        } else if (isFuture) {
          buffer.writeln('return ($exprSource).then((result) {');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(functionName, false));
          buffer.writeln('return result;');
          buffer.writeln('});');
        } else {
          final typePrefix =
              returnTypeStr != null &&
                  returnTypeStr != 'void' &&
                  returnTypeStr != 'dynamic'
              ? '$returnTypeStr '
              : '';
          buffer.writeln('return (($typePrefix result) {');
          if (postClauses.isNotEmpty) {
            buffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) buffer.write(_buildTraceExit(functionName, false));
          buffer.writeln('return result;');
          buffer.writeln('})($exprSource);');
        }
      } else {
        if (isVoid) {
          buffer.writeln('$exprSource;');
        } else {
          buffer.writeln('return $exprSource;');
        }
      }
      buffer.write('}');

      final startOffset = body.functionDefinition.offset;
      final length = body.end - startOffset;
      _replacements.add(_Replacement(startOffset, length, buffer.toString()));
    } else if (body is BlockFunctionBody) {
      final entryBuffer = StringBuffer();
      if (hasTrace) {
        entryBuffer.write(
          _buildTraceEntry(
            functionName,
            customTrace,
            node.functionExpression.parameters,
          ),
        );
      }
      if (preClauses.isNotEmpty) {
        entryBuffer.write(_buildPreCheck(preClauses));
      }

      if (entryBuffer.isNotEmpty) {
        _replacements.add(
          _Replacement(body.block.leftBracket.end, 0, '\n$entryBuffer\n'),
        );
      }
      if (postClauses.isNotEmpty || hasTrace) {
        _transformBlockReturns(
          body.block,
          postClauses,
          isVoid,
          isAsync,
          isFuture,
          returnTypeStr,
          hasTrace ? functionName : null,
        );

        final lastStatement = body.block.statements.isNotEmpty
            ? body.block.statements.last
            : null;
        if (isVoid && lastStatement is! ReturnStatement) {
          final exitBuffer = StringBuffer('\n');
          if (postClauses.isNotEmpty) {
            exitBuffer.write(_buildPostCheck(postClauses));
          }
          if (hasTrace) {
            exitBuffer.write(_buildTraceExit(functionName, true));
          }
          _replacements.add(
            _Replacement(
              body.block.rightBracket.offset,
              0,
              exitBuffer.toString(),
            ),
          );
        }
      }
    }
  }
}

class _ReturnStatementCollector extends RecursiveAstVisitor<void> {
  final List<ReturnStatement> returns = [];

  @override
  void visitReturnStatement(ReturnStatement node) {
    returns.add(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Stop traversal at nested function expressions and closures.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Stop traversal at nested local function declarations.
  }
}
