// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A supported platform for compilation of Dart libraries, including knowledge
/// of which core libraries are supported.
class DartPlatform {
  final List<String> _supportedLibraries;

  final String name;

  static const dartdevc = DartPlatform._('dartdevc', [
    'async',
    'collection',
    'convert',
    'core',
    'developer',
    'html',
    'html_common',
    'indexed_db',
    'isolate',
    'js',
    'js_util',
    'math',
    'svg',
    'typed_data',
    'web_audio',
    'web_gl',
    'web_sql',
  ]);
  static const dart2js = DartPlatform._('dart2js', [
    'async',
    'collection',
    'convert',
    'core',
    'developer',
    'html',
    'html_common',
    'indexed_db',
    'js',
    'js_util',
    'math',
    'svg',
    'typed_data',
    'web_audio',
    'web_gl',
    'web_sql',
  ]);
  static const dart2jsServer = DartPlatform._('dart2js_server', [
    'async',
    'collection',
    'convert',
    'core',
    'developer',
    'js',
    'js_util',
    'math',
    'typed_data',
  ]);
  static const flutter = DartPlatform._('flutter', [
    'async',
    'cli',
    'collection',
    'convert',
    'core',
    'developer',
    'io',
    'isolate',
    'math',
    'nativewrappers',
    'profiler',
    'typed_data',
    'ui',
    'vmservice_io',
  ]);
  static const vm = DartPlatform._('vm', [
    'async',
    'cli',
    'collection',
    'convert',
    'core',
    'developer',
    'io',
    'isolate',
    'math',
    'mirrors',
    'nativewrappers',
    'profiler',
    'typed_data',
    'vmservice_io',
  ]);

  factory DartPlatform(String name) {
    var platform = _byName[name];
    if (platform == null) {
      throw ArgumentError('Unrecognized paltform $name, the recognized '
          'platforms are ${_byName.keys.join(', ')}.');
    }
    return platform;
  }

  static const _byName = {
    'dart2js': dart2js,
    'dart2js_server': dart2jsServer,
    'dartdevc': dartdevc,
    'flutter': flutter,
    'vm': vm
  };

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
