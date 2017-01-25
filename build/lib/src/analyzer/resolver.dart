// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';

import '../asset/id.dart';
import '../builder/build_step.dart';

abstract class Resolver {
  /// Gets the resolved Dart library for an asset, or null if the AST has not
  /// been resolved.
  ///
  /// If the AST has not been resolved then this normally means that the
  /// transformer hosting this needs to be in an earlier phase.
  LibraryElement getLibrary(AssetId assetId);

  /// Gets all libraries accessible from the entry point, recursively.
  ///
  /// This includes all Dart SDK libraries as well.
  Iterable<LibraryElement> get libraries;

  /// Finds the first library identified by [libraryName], or null if no
  /// library can be found.
  LibraryElement getLibraryByName(String libraryName);
}

abstract class ReleasableResolver implements Resolver {
  /// Release this resolver so it can be updated by following build steps.
  void release();
}

abstract class Resolvers {
  Future<ReleasableResolver> get(BuildStep buildStep);
}
