// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Library {
  Object onDestroy();

  bool onSelfUpdate([Object data]);

  bool onChildUpdate(String childId, Library child, [Object data]);
}

/// Used for representation of amd modules that wraps several dart libraries
/// inside
class Module {
  /// Grouped by absolute library path starting with `package:`
  final Map<String, Library> libraries;

  Module(this.libraries);

  /// Calls onDestroy on each of underlined libraries and combines returned data
  Map<String, Object> onDestroy() {
    var data = <String, Object>{};
    for (var key in libraries.keys) {
      data[key] = libraries[key].onDestroy();
    }
    return data;
  }

  /// Calls onSelfUpdate on each of underlined libraries, returns aggregated
  /// result as "maximum" assuming true < null < false. Stops execution on first
  /// false result
  bool onSelfUpdate(Map<String, Object> data) {
    var result = true;
    for (var key in libraries.keys) {
      var success = libraries[key].onSelfUpdate(data[key]);
      if (success == false) {
        return false;
      } else if (success == null) {
        result = success;
      }
    }
    return result;
  }

  /// Calls onChildUpdate on each of underlined libraries, returns aggregated
  /// result as "maximum" assuming true < null < false. Stops execution on first
  /// false result
  bool onChildUpdate(String childId, Module child, Map<String, Object> data) {
    var result = true;
    // TODO(inayd): This is a rought implementation with lots of false positive
    // reloads. In current implementation every library in parent module should
    // know how to handle each library in child module. Also [roughLibraryKeyDecode]
    // depends on unreliable implementation details. Proper implementation
    // should rely on inner graph of dependencies between libraries in module,
    // to require only parent libraries which really depend on child ones to
    // handle it's updates. See dart-lang/build#1767.
    for (var parentKey in libraries.keys) {
      for (var childKey in child.libraries.keys) {
        var success = libraries[parentKey]
            .onChildUpdate(childKey, child.libraries[childKey], data[childKey]);
        if (success == false) {
          return false;
        } else if (success == null) {
          result = success;
        }
      }
    }
    return result;
  }
}
