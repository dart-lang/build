import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_style/dart_style.dart';

import 'clause_emitter.dart';
import 'exit_rewriter.dart';

/// Adds [import] to transformed source that mentions any of [markers].
///
/// A clause can use a name that the library under transformation does not
/// import, most often an extension member, because the clause is written by
/// hand and is not subject to the analyzer until it is woven in. Cofoja solves
/// this with `@ContractImport` on the enclosing type. Until that exists here,
/// the caller states the rules.
class ContractImportRule {
  final List<String> markers;
  final String import;

  const ContractImportRule({required this.markers, required this.import});
}

/// Transforms Dart source code to embed executable checks for
/// `@Requires`, `@Ensures`, and `@Invariant` contracts.
String transformContracts(
  String source, {
  List<ContractImportRule> importRules = const [],
}) {
  final parseResult = parseString(content: source, throwIfDiagnostics: false);
  if (parseResult.errors.isNotEmpty) {
    final messages = parseResult.errors.map((e) => e.message).join('\n');
    throw FormatException('Source has parse errors:\n$messages');
  }
  final unit = parseResult.unit;

  final collector = _ContractTransformCollector(source);
  unit.accept(collector);

  if (collector.isEmpty) return source;

  // A library that already imports the target does not need it again. The
  // existing import is often relative where the rule is absolute, so compare
  // file names: importing two libraries of the same name is rare, and getting
  // it wrong fails visibly as an undefined name in the woven copy.
  final importedFileNames = {
    for (final directive in unit.directives.whereType<ImportDirective>())
      if (directive.uri.stringValue case final uri?) uri.split('/').last,
  };

  var transformed = collector.applyReplacements();
  for (final rule in importRules) {
    if (importedFileNames.contains(rule.import.split('/').last)) continue;
    if (!rule.markers.any(transformed.contains)) continue;
    final firstImport = transformed.indexOf('import ');
    if (firstImport == -1) continue;
    transformed =
        '${transformed.substring(0, firstImport)}'
        "import '${rule.import}';\n"
        '${transformed.substring(firstImport)}';
  }
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
        clauses.add(_stringValue(arg, name));
      }
    }
    return clauses;
  }

  /// The clauses of each `@ThrowEnsures` annotation in [metadata].
  ///
  /// The first argument names the exception type and the rest are clauses. One
  /// annotation covers one type; repeat the annotation for more types.
  List<ThrowClauses> _extractThrowClauses(NodeList<Annotation> metadata) {
    final result = <ThrowClauses>[];
    for (final annotation in metadata) {
      if (annotation.name.name != 'ThrowEnsures') continue;
      final args = annotation.arguments?.arguments;
      if (args == null || args.length < 2) {
        throw const FormatException(
          '@ThrowEnsures annotation requires an exception type and at least '
          'one contract expression string.',
        );
      }
      result.add(
        ThrowClauses(
          type: source.substring(args.first.offset, args.first.end),
          clauses: [
            for (final arg in args.skip(1)) _stringValue(arg, 'ThrowEnsures'),
          ],
        ),
      );
    }
    return result;
  }

  /// The value of [arg], which must be a string literal with no interpolation.
  String _stringValue(Argument arg, String name) {
    if (arg is SimpleStringLiteral) return arg.value;
    if (arg is StringLiteral) {
      final value = arg.stringValue;
      if (value != null) return value;
      throw FormatException(
        '@$name contract expression must be a non-empty string literal.',
      );
    }
    throw FormatException(
      '@$name contract expression must be a string literal, '
      'got: ${source.substring(arg.offset, arg.end)}',
    );
  }

  String? _currentClassName;
  bool _currentClassIsImmutable = false;

  static const _annotationClassNames = {
    'Requires',
    'Ensures',
    'ThrowEnsures',
    'Invariant',
  };

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final declaredClasses = {
      for (final declaration in node.declarations.whereType<ClassDeclaration>())
        declaration.namePart.typeName.lexeme,
    };
    if (declaredClasses.intersection(_annotationClassNames).isNotEmpty) {
      final support = ClauseEmitter.runtimeSupport(
        includeContracts: !declaredClasses.contains('Contracts'),
        includeViolation: !declaredClasses.contains('ContractViolation'),
      );
      if (support.isNotEmpty) {
        _replacements.add(_Replacement(source.length, 0, '\n$support'));
      }
    }
    super.visitCompilationUnit(node);
  }

  bool _checkClassImmutability(ClassDeclaration node) {
    final implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (final iface in implementsClause.interfaces) {
        if (iface.name.lexeme == 'Built') return true;
      }
    }
    final body = node.body;
    if (body is! BlockClassBody) return false;
    var hasInstanceFields = false;
    for (final member in body.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        hasInstanceFields = true;
        if (!member.fields.isFinal && !member.fields.isConst) {
          return false;
        }
        final typeStr = member.fields.type?.toSource() ?? '';
        if (typeStr.startsWith('Set<') ||
            typeStr.startsWith('Map<') ||
            typeStr.startsWith('List<') ||
            typeStr.startsWith('Queue<') ||
            typeStr.startsWith('MapBuilder<') ||
            typeStr.startsWith('SetBuilder<') ||
            typeStr.startsWith('ListBuilder<') ||
            typeStr.startsWith('StringBuffer')) {
          return false;
        }
      }
    }
    return hasInstanceFields;
  }

  bool _mightMutateState(MethodDeclaration node) {
    if (_currentClassIsImmutable) return false;
    if (node.isSetter) return true;
    final detector = _MutationDetector();
    node.body.accept(detector);
    return detector.mightMutate;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final previousClassName = _currentClassName;
    final previousImmutable = _currentClassIsImmutable;
    _currentClassName = node.namePart.typeName.lexeme;
    _currentClassIsImmutable = _checkClassImmutability(node);

    final invariantClauses = _extractClauses(node.metadata, 'Invariant');
    final hasInvariant = invariantClauses.isNotEmpty;

    if (hasInvariant) {
      // Inject the `_checkInvariants` extension after the class.
      final extension = ClauseEmitter.invariantExtension(
        _currentClassName!,
        node.namePart.typeParameters,
        invariantClauses,
      );
      _replacements.add(_Replacement(node.end, 0, '\n$extension\n'));
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
      _currentClassIsImmutable = previousImmutable;
    }
  }

  /// Rejects parameters that collide with names the weaver binds for clauses.
  void _checkReservedParameterNames(
    FormalParameterList? parameters, {
    required bool hasResultBinding,
    required bool hasThrow,
  }) {
    if (parameters == null) return;
    for (final parameter in parameters.parameters) {
      final name = parameter.name?.lexeme;
      if (hasResultBinding && name == 'result') {
        throw const FormatException(
          '@Ensures cannot be used on a function with a parameter named '
          '"result".',
        );
      }
      if (hasThrow && name == 'signal') {
        throw const FormatException(
          '@ThrowEnsures cannot be used on a function with a parameter named '
          '"signal".',
        );
      }
    }
  }

  void _transformConstructor(
    ConstructorDeclaration node,
    bool classHasInvariant,
  ) {
    if (node.redirectedConstructor != null) return;
    if (node.constKeyword != null) return;

    // Constructors have their own entry and exit assembly, which has no place
    // to put a catch clause. Silently ignoring the annotation would be worse.
    if (_extractThrowClauses(node.metadata).isNotEmpty) {
      throw const FormatException(
        '@ThrowEnsures is not supported on constructors.',
      );
    }

    if (node.factoryKeyword != null) {
      final preClauses = _extractClauses(node.metadata, 'Requires');
      final postClauses = _extractClauses(node.metadata, 'Ensures');
      if (preClauses.isEmpty && postClauses.isEmpty) return;
      _checkReservedParameterNames(
        node.parameters,
        hasResultBinding: postClauses.isNotEmpty,
        hasThrow: false,
      );

      final body = node.body;
      final exitRewriter = ExitRewriter(
        returnType: _currentClassName,
        isAsync: false,
      );
      if (body is ExpressionFunctionBody) {
        final exprSource = source.substring(
          body.expression.offset,
          body.expression.end,
        );
        final buffer = StringBuffer('{\n');
        if (preClauses.isNotEmpty) {
          buffer.write(ClauseEmitter.preconditions(preClauses));
        }

        if (postClauses.isNotEmpty) {
          buffer.writeln(
            exitRewriter.returnValue(
              exprSource,
              ClauseEmitter.postconditions(postClauses),
            ),
          );
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
              '\n${ClauseEmitter.preconditions(preClauses)}\n',
            ),
          );
        }
        if (postClauses.isNotEmpty) {
          _transformBlockReturns(body.block, postClauses, exitRewriter);
        }
      }
      return;
    }

    if (node.initializers.any((i) => i is RedirectingConstructorInvocation)) {
      return;
    }

    final preClauses = _extractClauses(node.metadata, 'Requires');
    final postClauses = _extractClauses(node.metadata, 'Ensures');
    final hasPre = preClauses.isNotEmpty;
    final hasPost = postClauses.isNotEmpty;
    if (!hasPre && !hasPost && !classHasInvariant) return;
    _checkReservedParameterNames(
      node.parameters,
      hasResultBinding: false,
      hasThrow: false,
    );

    final body = node.body;
    if (body is EmptyFunctionBody) {
      final buffer = StringBuffer('{\n');
      if (hasPre) buffer.write(ClauseEmitter.preconditions(preClauses));
      if (classHasInvariant) buffer.writeln('this._checkInvariants();');
      if (hasPost) buffer.write(ClauseEmitter.postconditions(postClauses));
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
            '\n${ClauseEmitter.preconditions(preClauses)}\n',
          ),
        );
      }
      if (classHasInvariant || hasPost) {
        final collector = _ReturnStatementCollector();
        body.block.accept(collector);
        for (final ret in collector.returns) {
          final retBuffer = StringBuffer('{\n');
          if (classHasInvariant) retBuffer.writeln('this._checkInvariants();');
          if (hasPost) {
            retBuffer.write(ClauseEmitter.postconditions(postClauses));
          }
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
          if (classHasInvariant) {
            exitBuffer.writeln('this._checkInvariants();');
          }
          if (hasPost) {
            exitBuffer.write(ClauseEmitter.postconditions(postClauses));
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

  void _transformMethod(MethodDeclaration node, bool classHasInvariant) {
    if (node.body is EmptyFunctionBody) return;

    final preClauses = _extractClauses(node.metadata, 'Requires');
    final postClauses = _extractClauses(node.metadata, 'Ensures');
    final throwClauses = _extractThrowClauses(node.metadata);
    final returnType = node.returnType?.toSource();
    final isVoid = node.isSetter || returnType == 'void';
    _checkReservedParameterNames(
      node.parameters,
      hasResultBinding: postClauses.isNotEmpty && !isVoid,
      hasThrow: throwClauses.isNotEmpty,
    );
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
        throwClauses.isEmpty &&
        !checkInvariant) {
      return;
    }

    _transformBody(
      node.body,
      returnType: returnType,
      isVoid: isVoid,
      preClauses: preClauses,
      postClauses: postClauses,
      guard: _BodyGuard(
        invariant: checkInvariant
            ? _InvariantHooks(
                className: _currentClassName!,
                mightMutate: _mightMutateState(node),
              )
            : null,
        throwClauses: throwClauses,
      ),
    );
  }

  /// Weaves the checks for one function or method into [body].
  void _transformBody(
    FunctionBody body, {
    required String? returnType,
    required bool isVoid,
    required List<String> preClauses,
    required List<String> postClauses,
    required _BodyGuard guard,
  }) {
    final exitRewriter = ExitRewriter(
      returnType: returnType,
      isAsync: body.isAsynchronous,
    );

    if (body is ExpressionFunctionBody) {
      final exprSource = source.substring(
        body.expression.offset,
        body.expression.end,
      );

      final buffer = StringBuffer('{\n');
      final invariant = guard.invariant;
      if (invariant != null) buffer.write(invariant.check);
      if (preClauses.isNotEmpty) {
        buffer.write(ClauseEmitter.preconditions(preClauses));
      }
      buffer.write(guard.open);

      if (postClauses.isNotEmpty) {
        if (isVoid) {
          buffer.writeln('$exprSource;');
          buffer.write(ClauseEmitter.postconditions(postClauses));
        } else {
          buffer.writeln(
            exitRewriter.returnValue(
              exprSource,
              ClauseEmitter.postconditions(postClauses),
            ),
          );
        }
      } else if (isVoid) {
        buffer.writeln('$exprSource;');
      } else {
        buffer.writeln('return $exprSource;');
      }

      buffer.write(guard.close);
      buffer.write('}');

      final startOffset = body.functionDefinition.offset;
      _replacements.add(
        _Replacement(startOffset, body.end - startOffset, buffer.toString()),
      );
    } else if (body is BlockFunctionBody) {
      final entryBuffer = StringBuffer();
      final invariant = guard.invariant;
      if (invariant != null) entryBuffer.write(invariant.check);
      if (preClauses.isNotEmpty) {
        entryBuffer.write(ClauseEmitter.preconditions(preClauses));
      }
      entryBuffer.write(guard.open);

      if (entryBuffer.isNotEmpty) {
        _replacements.add(
          _Replacement(body.block.leftBracket.end, 0, '\n$entryBuffer\n'),
        );
      }

      if (postClauses.isNotEmpty) {
        _transformBlockReturns(body.block, postClauses, exitRewriter);
      }

      final closingBuffer = StringBuffer('\n');
      final lastStatement = body.block.statements.isNotEmpty
          ? body.block.statements.last
          : null;
      if (isVoid && lastStatement is! ReturnStatement) {
        if (postClauses.isNotEmpty) {
          closingBuffer.write(ClauseEmitter.postconditions(postClauses));
        }
      }
      closingBuffer.write(guard.close);
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
    ExitRewriter exitRewriter,
  ) {
    final collector = _ReturnStatementCollector();
    block.accept(collector);

    for (final statement in collector.returns) {
      final expr = statement.expression;
      if (expr != null) {
        final exprSource = source.substring(expr.offset, expr.end);
        _replacements.add(
          _Replacement(
            statement.offset,
            statement.length,
            exitRewriter.returnValue(
              exprSource,
              ClauseEmitter.postconditions(postClauses),
            ),
          ),
        );
      } else {
        final buffer = StringBuffer('{\n')
          ..write(ClauseEmitter.postconditions(postClauses))
          ..writeln('return;')
          ..write('}');

        _replacements.add(
          _Replacement(statement.offset, statement.length, buffer.toString()),
        );
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final preClauses = _extractClauses(node.metadata, 'Requires');
    final postClauses = _extractClauses(node.metadata, 'Ensures');
    final throwClauses = _extractThrowClauses(node.metadata);
    if (preClauses.isEmpty && postClauses.isEmpty && throwClauses.isEmpty) {
      return;
    }
    final returnType = node.returnType?.toSource();
    final isVoid = returnType == 'void';
    _checkReservedParameterNames(
      node.functionExpression.parameters,
      hasResultBinding: postClauses.isNotEmpty && !isVoid,
      hasThrow: throwClauses.isNotEmpty,
    );

    _transformBody(
      node.functionExpression.body,
      returnType: returnType,
      isVoid: isVoid,
      preClauses: preClauses,
      postClauses: postClauses,
      guard: _BodyGuard(throwClauses: throwClauses),
    );
  }
}

/// The invariant checks woven around a method body.
class _InvariantHooks {
  _InvariantHooks({required this.className, required this.mightMutate});

  final String className;

  /// Whether the body can change the object, so that a memoized check result
  /// must be discarded on exit.
  final bool mightMutate;

  /// The check that runs on entry.
  String get check => 'this._checkInvariants();\n';
}

/// The checks woven around a body so that they run however it exits.
class _BodyGuard {
  _BodyGuard({this.invariant, this.throwClauses = const []});

  final _InvariantHooks? invariant;
  final List<ThrowClauses> throwClauses;

  bool get isEmpty => invariant == null && throwClauses.isEmpty;

  /// Opens the region that [close] closes.
  String get open {
    if (isEmpty) return '';
    // The exception being unwound is captured so that a violation reported by
    // the invariant check can name the exception it discards.
    final declaration = invariant == null ? '' : 'Object? \$inFlight;\n';
    return '${declaration}try {\n';
  }

  String get close {
    if (isEmpty) return '';
    final invariant = this.invariant;
    final buffer = StringBuffer();
    for (final clauses in throwClauses) {
      buffer.write(
        ClauseEmitter.exceptionalPostconditions(
          clauses,
          beforeChecks: invariant == null ? '' : '\$inFlight = signal;\n',
        ),
      );
    }
    if (invariant == null) return '}\n$buffer';

    buffer.writeln('catch (\$thrown) {');
    buffer.writeln(r'$inFlight = $thrown;');
    buffer.writeln('rethrow;');
    buffer.writeln('} finally {');
    if (invariant.mightMutate) {
      buffer.writeln(
        '${ClauseEmitter.invariantExtensionName(invariant.className)}'
        '._invariantVerified[this] = false;',
      );
    }
    buffer.writeln(r'this._checkInvariants(during: $inFlight);');
    buffer.writeln('}');
    return '} $buffer';
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

class _MutationDetector extends RecursiveAstVisitor<void> {
  bool mightMutate = false;

  static const _mutatingPrefixes = [
    'add',
    'remove',
    'clear',
    'put',
    'update',
    'replace',
    'set',
    'insert',
    'fill',
    'sort',
    'shuffle',
    'mark',
    'copy',
    'record',
    'reset',
    'write',
    'delete',
    'evict',
    'invalidate',
    'register',
    'unregister',
    'modify',
    'mutate',
  ];

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    mightMutate = true;
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.lexeme == '++' || node.operator.lexeme == '--') {
      mightMutate = true;
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '++' || node.operator.lexeme == '--') {
      mightMutate = true;
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    for (final prefix in _mutatingPrefixes) {
      if (name.startsWith(prefix)) {
        mightMutate = true;
        break;
      }
    }
    super.visitMethodInvocation(node);
  }
}
