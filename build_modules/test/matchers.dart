// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build_modules/src/meta_module.dart';
import 'package:build_modules/src/modules.dart';
import 'package:test/test.dart';

/// Matches an encoded [Module] against an [expected] Module instance.
Matcher encodedMatchesModule(Module expected) => EncodedModuleMatcher(expected);

/// Matches an encoded [MetaModule] against an [expected] Module instance.
Matcher encodedMatchesMetaModule(MetaModule expected) =>
    EncodedMetaModuleMatcher(expected);

/// Matches a [Module] against an [expected] Module instance.
Matcher matchesModule(Module expected) => ModuleMatcher(expected);

/// A [Matcher] for an encoded [MetaModule] against an [expected] instance.
class EncodedMetaModuleMatcher extends Matcher {
  final MetaModule expected;

  EncodedMetaModuleMatcher(this.expected);

  @override
  bool matches(actual, description) {
    if (actual is List<int>) {
      actual = utf8.decode(actual as List<int>);
    }
    if (actual is! String) return false;
    var jSon = json.decode(actual as String) as Map<String, dynamic>;
    var meta = MetaModule.fromJson(jSon);
    return unorderedMatches(expected.modules.map(matchesModule))
        .matches(meta.modules, description);
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    try {
      if (item is List<int>) {
        item = utf8.decode(item as List<int>);
      }
      if (item is! String) {
        return mismatchDescription.add('Was neither `List<int>` or `String`.');
      }
      return mismatchDescription.add('Had content $item');
    } catch (_) {
      return mismatchDescription.add('Could not be decoded');
    }
  }

  @override
  Description describe(Description description) =>
      description.add(json.encode(expected.toJson()).toString());
}

class ModuleMatcher extends Matcher {
  final Module expected;

  ModuleMatcher(this.expected);

  @override
  bool matches(actual, description) {
    if (actual is! Module) return false;
    return actual.primarySource == expected.primarySource &&
        unorderedEquals(expected.sources)
            .matches(actual.sources, description) &&
        unorderedEquals(expected.directDependencies)
            .matches(actual.directDependencies, description);
  }

  @override
  Description describe(Description description) =>
      description.add(json.encode(expected.toJson()).toString());
}

/// A [Matcher] for an encoded [Module] against an [expected] instance.
class EncodedModuleMatcher extends Matcher {
  final Module expected;

  EncodedModuleMatcher(this.expected);

  @override
  bool matches(actual, description) {
    if (actual is List<int>) {
      actual = utf8.decode(actual as List<int>);
    }
    if (actual is! String) return false;
    var jSon = json.decode(actual as String) as Map<String, dynamic>;
    var module = Module.fromJson(jSon);
    return ModuleMatcher(expected).matches(module, description);
  }

  @override
  Description describe(Description description) =>
      description.add(json.encode(expected.toJson()).toString());
}
