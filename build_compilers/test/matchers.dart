// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/summary/idl.dart';
import 'package:test/test.dart';

import 'package:build_compilers/src/modules.dart';

/// Matches an encoded [Module] against an [expected] Module instance.
encodedMatchesModule(Module expected) => new EncodedModuleMatcher(expected);

/// A [Matcher] for an analyzer summary that matches against the linked uris.
class HasLinkedUris extends CustomMatcher {
  HasLinkedUris(matcher)
      : super('Summary with linked uris', 'linkedLibraryUris', matcher);

  @override
  featureValueOf(summaryBytes) {
    var bundle = new PackageBundle.fromBuffer(summaryBytes as List<int>);
    return bundle.linkedLibraryUris;
  }
}

/// A [Matcher] for an analyzer summary that matches against the unlinked uris.
class HasUnlinkedUris extends CustomMatcher {
  HasUnlinkedUris(matcher)
      : super('Summary with unlinked uris', 'unlinkedLibraryUris', matcher);

  @override
  featureValueOf(summaryBytes) {
    var bundle = new PackageBundle.fromBuffer(summaryBytes as List<int>);
    return bundle.unlinkedUnitUris;
  }
}

/// A [Matcher] for an encoded [Module] against an [expected] instance.
class EncodedModuleMatcher extends Matcher {
  final Module expected;

  EncodedModuleMatcher(this.expected);

  @override
  bool matches(actual, description) {
    if (actual is List<int>) {
      actual = UTF8.decode(actual as List<int>);
    }
    if (actual is! String) return false;
    var json = JSON.decode(actual as String) as Map<String, dynamic>;
    var module = new Module.fromJson(json);

    return module.primarySource == expected.primarySource &&
        unorderedEquals(expected.sources)
            .matches(module.sources, description) &&
        unorderedEquals(expected.directDependencies)
            .matches(module.directDependencies, description);
  }

  @override
  Description describe(Description description) =>
      description.add(JSON.encode(expected.toJson()).toString());
}
