import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_style/dart_style.dart';

/// Transforms Dart source code to embed executable checks for
/// `@Pre`, `@Post`, and `@Invariant` contracts.
String transformContracts(String source) {
  final parseResult = parseString(content: source, throwIfDiagnostics: false);
  final unit = parseResult.unit;

  final collector = _ContractTransformCollector(source);
  unit.accept(collector);

  final transformed = collector.applyReplacements();
  try {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(transformed);
  } catch (_) {
    return transformed;
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
      if (args == null) continue;
      for (final arg in args) {
        if (arg is SimpleStringLiteral) {
          clauses.add(arg.value);
        } else if (arg is StringLiteral) {
          final val = arg.stringValue;
          if (val != null) clauses.add(val);
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

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final invariantClauses = _extractClauses(node.metadata, 'Invariant');
    final hasInvariant = invariantClauses.isNotEmpty;

    if (hasInvariant) {
      // Inject _checkInvariants() method before right bracket of class.
      _replacements.add(
        _Replacement(
          body.rightBracket.offset,
          0,
          '\n${_buildInvariantMethod(invariantClauses)}\n',
        ),
      );
    }

    for (final member in body.members) {
      if (member is ConstructorDeclaration) {
        _transformConstructor(member, hasInvariant);
      } else if (member is MethodDeclaration) {
        _transformMethod(member, hasInvariant);
      }
    }
  }

  void _transformConstructor(
    ConstructorDeclaration node,
    bool classHasInvariant,
  ) {
    if (node.redirectedConstructor != null) return;
    if (node.factoryKeyword != null) return;
    if (node.constKeyword != null) return;

    final preClauses = _extractClauses(node.metadata, 'Pre');
    final hasPre = preClauses.isNotEmpty;
    if (!hasPre && !classHasInvariant) return;

    final body = node.body;
    if (body is EmptyFunctionBody) {
      final buffer = StringBuffer('{\n');
      if (hasPre) buffer.write(_buildPreCheck(preClauses));
      if (classHasInvariant) buffer.writeln('_checkInvariants();');
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
      if (classHasInvariant) {
        _replacements.add(
          _Replacement(
            body.block.rightBracket.offset,
            0,
            '\n_checkInvariants();\n',
          ),
        );
      }
    }
  }

  void _transformMethod(MethodDeclaration node, bool classHasInvariant) {
    if (node.body is EmptyFunctionBody) return;

    final preClauses = _extractClauses(node.metadata, 'Pre');
    final postClauses = _extractClauses(node.metadata, 'Post');
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

    if (preClauses.isEmpty && postClauses.isEmpty && !checkInvariant) {
      return;
    }

    final body = node.body;
    if (body is ExpressionFunctionBody) {
      final exprSource = source.substring(
        body.expression.offset,
        body.expression.end,
      );
      final isVoid = node.returnType?.toSource() == 'void';

      final buffer = StringBuffer('{\n');
      if (checkInvariant) buffer.writeln('_checkInvariants();');
      if (preClauses.isNotEmpty) buffer.write(_buildPreCheck(preClauses));

      if (postClauses.isNotEmpty) {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          buffer.write(_buildPostCheck(postClauses));
          if (checkInvariant) buffer.writeln('_checkInvariants();');
        } else {
          buffer.writeln('final result = $exprSource;');
          buffer.write(_buildPostCheck(postClauses));
          if (checkInvariant) buffer.writeln('_checkInvariants();');
          buffer.writeln('return result;');
        }
      } else {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          if (checkInvariant) buffer.writeln('_checkInvariants();');
        } else {
          if (checkInvariant) {
            buffer.writeln('final result = $exprSource;');
            buffer.writeln('_checkInvariants();');
            buffer.writeln('return result;');
          } else {
            buffer.writeln('return $exprSource;');
          }
        }
      }
      buffer.write('}');

      final startOffset = body.functionDefinition.offset;
      final length = body.end - startOffset;
      _replacements.add(_Replacement(startOffset, length, buffer.toString()));
    } else if (body is BlockFunctionBody) {
      final entryBuffer = StringBuffer();
      if (checkInvariant) entryBuffer.writeln('_checkInvariants();');
      if (preClauses.isNotEmpty) {
        entryBuffer.write(_buildPreCheck(preClauses));
      }

      if (checkInvariant && postClauses.isEmpty) {
        // Wrap method execution with try-finally to guarantee invariant
        // check on exit.
        entryBuffer.writeln('try {');
        _replacements.add(
          _Replacement(body.block.leftBracket.end, 0, '\n$entryBuffer\n'),
        );
        _replacements.add(
          _Replacement(
            body.block.rightBracket.offset,
            0,
            '\n} finally {\n  _checkInvariants();\n}\n',
          ),
        );
      } else {
        if (entryBuffer.isNotEmpty) {
          _replacements.add(
            _Replacement(body.block.leftBracket.end, 0, '\n$entryBuffer\n'),
          );
        }

        if (postClauses.isNotEmpty) {
          _transformBlockReturns(body.block, postClauses, checkInvariant);
        }
      }
    }
  }

  void _transformBlockReturns(
    Block block,
    List<String> postClauses,
    bool checkInvariant,
  ) {
    for (final statement in block.statements) {
      if (statement is ReturnStatement) {
        final expr = statement.expression;
        if (expr != null) {
          final exprSource = source.substring(expr.offset, expr.end);
          final buffer = StringBuffer('return () {\n');
          buffer.writeln('  final result = $exprSource;');
          buffer.write(_buildPostCheck(postClauses));
          if (checkInvariant) buffer.writeln('  _checkInvariants();');
          buffer.writeln('  return result;');
          buffer.write('}();');

          _replacements.add(
            _Replacement(statement.offset, statement.length, buffer.toString()),
          );
        } else {
          final buffer = StringBuffer('{\n');
          buffer.write(_buildPostCheck(postClauses));
          if (checkInvariant) buffer.writeln('_checkInvariants();');
          buffer.writeln('return;');
          buffer.write('}');

          _replacements.add(
            _Replacement(statement.offset, statement.length, buffer.toString()),
          );
        }
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final preClauses = _extractClauses(node.metadata, 'Pre');
    final postClauses = _extractClauses(node.metadata, 'Post');
    if (preClauses.isEmpty && postClauses.isEmpty) return;

    final body = node.functionExpression.body;
    if (body is ExpressionFunctionBody) {
      final exprSource = source.substring(
        body.expression.offset,
        body.expression.end,
      );
      final isVoid = node.returnType?.toSource() == 'void';

      final buffer = StringBuffer('{\n');
      if (preClauses.isNotEmpty) buffer.write(_buildPreCheck(preClauses));

      if (postClauses.isNotEmpty) {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          buffer.write(_buildPostCheck(postClauses));
        } else {
          buffer.writeln('final result = $exprSource;');
          buffer.write(_buildPostCheck(postClauses));
          buffer.writeln('return result;');
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
        _transformBlockReturns(body.block, postClauses, false);
      }
    }
  }
}
