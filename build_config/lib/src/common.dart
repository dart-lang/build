// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

BuilderOptions builderOptionsFromJson(Map<String, dynamic> config) =>
    new BuilderOptions(config);

final _defaultDependenciesZoneKey =
    new Symbol('buildConfigDefaultDependencies');
final _packageZoneKey = new Symbol('buildConfigPackage');

T runInBuildConfigZone<T>(
        T fn(), String package, List<String> defaultDependencies) =>
    runZoned(fn, zoneValues: {
      _packageZoneKey: package,
      _defaultDependenciesZoneKey: defaultDependencies,
    });

String get currentPackage {
  var package = Zone.current[_packageZoneKey] as String;
  assert(package != null);
  return package;
}

List<String> get currentPackageDefaultDependencies {
  var defaultDependencies =
      Zone.current[_defaultDependenciesZoneKey] as List<String>;
  assert(defaultDependencies != null);
  return defaultDependencies;
}
