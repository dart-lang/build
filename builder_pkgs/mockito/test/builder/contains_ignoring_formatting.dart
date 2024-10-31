// Copyright 2024 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:test/test.dart';

/// Returns a [Matcher] that checks that the actual string of Dart code
/// contains [expected] when ignoring differences due to formatting: whitespace
/// and trailing commas.
Matcher containsIgnoringFormatting(String expected) =>
    _ContainsIgnoringFormattingMatcher(expected);

/// Matches a string that contains a given string, ignoring differences related
/// to formatting: whitespace and trailing commas.
class _ContainsIgnoringFormattingMatcher extends Matcher {
  /// Matches one or more whitespace characters.
  static final _whitespacePattern = RegExp(r'\s+');

  /// Matches a trailing comma preceding a closing bracket character.
  static final _trailingCommaPattern = RegExp(r',\s*([)}\]])');

  /// The string that the actual value must contain in order for the match to
  /// succeed.
  final String _expected;

  _ContainsIgnoringFormattingMatcher(this._expected);

  @override
  Description describe(Description description) {
    return description
        .add('Contains "$_expected" when ignoring source formatting');
  }

  @override
  bool matches(item, Map matchState) =>
      _stripFormatting(item.toString()).contains(_stripFormatting(_expected));

  /// Removes whitespace and trailing commas.
  ///
  /// Note that the result is not valid code because it means adjacent
  ///.identifiers and operators may be joined in ways that break the semantics.
  /// The goal is not to produce an but valid version of the code, just to
  /// produce a string that will reliably match the actual string when it has
  /// also been stripped the same way.
  String _stripFormatting(String code) => code
      .replaceAll(_whitespacePattern, '')
      .replaceAllMapped(_trailingCommaPattern, (match) => match[1]!)
      .trim();
}
