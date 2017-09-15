// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/summary/idl.dart';
import 'package:test/test.dart';

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

/// A matcher that decodes bytes and matches against the resulting string.
class Utf8Decoded extends CustomMatcher {
  Utf8Decoded(matcher) : super('Utf8 decoded bytes', 'UTF8.decode', matcher);

  @override
  featureValueOf(bytes) => UTF8.decode(bytes as List<int>);
}
