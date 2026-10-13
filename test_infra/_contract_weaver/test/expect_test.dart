// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_contract_weaver/contract_weaver.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Weaves each `test/expect/*.dart` and compares the result, formatted so
/// that it is readable, with the checked-in `.dart.expect` file beside it.
///
/// To update the expectations, run with `UPDATE_EXPECTATIONS=1`.
void main() {
  final update = Platform.environment['UPDATE_EXPECTATIONS'] == '1';
  final inputs = [
    for (final entity in Directory(p.join('test', 'expect')).listSync())
      if (entity is File && entity.path.endsWith('.dart')) entity,
  ]..sort((a, b) => a.path.compareTo(b.path));

  for (final input in inputs) {
    test(p.basename(input.path), () {
      final woven = _formatter.format(
        ContractWeaver().weave(input.readAsStringSync()),
      );
      final expectFile = File('${input.path}.expect');
      if (update) {
        expectFile.writeAsStringSync(woven);
        return;
      }
      expect(
        expectFile.existsSync(),
        isTrue,
        reason:
            'Missing ${expectFile.path}; run with UPDATE_EXPECTATIONS=1 '
            'to create it.',
      );
      expect(
        woven,
        expectFile.readAsStringSync(),
        reason:
            'Woven output differs from ${expectFile.path}; if the change is '
            'intended, run with UPDATE_EXPECTATIONS=1.',
      );
    });

    test('${p.basename(input.path)} keeps line numbers', () {
      final source = input.readAsStringSync();
      final woven = ContractWeaver().weave(source);
      final original = _wordsByLine(source);
      final weaved = _wordsByLine(woven);
      for (final MapEntry(key: line, value: words) in original.entries) {
        final remaining = [...?weaved[line]];
        for (final word in words) {
          expect(
            remaining.remove(word),
            isTrue,
            reason:
                '`$word` from line $line is not on line $line of the woven '
                'code:\n${woven.split('\n')[line - 1]}',
          );
        }
      }
    });
  }
}

final _formatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

const _literals = {
  TokenType.DOUBLE,
  TokenType.HEXADECIMAL,
  TokenType.INT,
  TokenType.STRING,
};

/// The identifiers, keywords and literals of [source], by one based line.
Map<int, List<String>> _wordsByLine(String source) {
  final result = parseString(content: source);
  final words = <int, List<String>>{};
  for (var token = result.unit.beginToken; !token.isEof; token = token.next!) {
    if (token.isIdentifier ||
        token.isKeyword ||
        _literals.contains(token.type)) {
      final line = result.lineInfo.getLocation(token.offset).lineNumber;
      (words[line] ??= []).add(token.lexeme);
    }
  }
  return words;
}
