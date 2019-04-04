// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A supported "platform" for compilation of Dart libraries.
///
/// Each "platform" has its own compilation pipeline and builders, and could
/// differ from other platforms in many ways:
///
/// - The core libs that are supported
/// - The implementations of the core libs
/// - The compilation steps that are required (frontends or backends could be
///   different).
///
/// Typically these should correspond to `libraries.json` files in the SDK.
///
/// New platforms should be created with [register], and can later be
/// fetched by name using the [DartPlatform.byName] static method.
class DartPlatform {
  /// A list of all registered platforms by name, populated by
  /// [register].
  static final _platformsByName = <String, DartPlatform>{};

  final List<String> _supportedLibraries;

  final String name;

  /// Returns a [DartPlatform] instance by name.
  ///
  /// Throws an [UnrecognizedDartPlatform] if [name] has not been
  /// registered with [DartPlatform.register].
  static DartPlatform byName(String name) =>
      _platformsByName[name] ?? (throw UnrecognizedDartPlatform(name));

  /// Registers a new [DartPlatform].
  ///
  /// Throws a [DartPlatformAlreadyRegistered] if [name] has already
  /// been registered by somebody else.
  static DartPlatform register(String name, List<String> supportedLibraries) {
    if (_platformsByName.containsKey(name)) {
      throw DartPlatformAlreadyRegistered(name);
    }

    return _platformsByName[name] =
        DartPlatform._(name, List.unmodifiable(supportedLibraries));
  }

  const DartPlatform._(this.name, this._supportedLibraries);

  /// Returns whether or not [library] is supported on this platform.
  ///
  /// The [library] is path portion of a `dart:` import (should not include the
  /// scheme).
  bool supportsLibrary(String library) => _supportedLibraries.contains(library);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(other) => other is DartPlatform && other.name == name;
}

class DartPlatformAlreadyRegistered implements Exception {
  final String name;

  const DartPlatformAlreadyRegistered(this.name);

  @override
  String toString() => 'The platform `$name`, has already been registered.';
}

class UnrecognizedDartPlatform implements Exception {
  final String name;

  const UnrecognizedDartPlatform(this.name);

  @override
  String toString() => 'Unrecognized platform `$name`, it must be registered '
      'first using `DartPlatform.register`';
}
