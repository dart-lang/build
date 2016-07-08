// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is kept as a separate library from the generator intentionally to
/// minimize transitive dependencies of types that are annotated as
/// serializable.
library source_gen.json_serial.annotation;

class JsonSerializable {
  final bool createFactory;
  final bool createToJson;

  const JsonSerializable({bool createFactory: true, bool createToJson: true})
      : this.createFactory = createFactory,
        this.createToJson = createToJson;
}

/// Customizes the name of the JSON key for a field.
///
/// If omitted, the resulting JSON key will be the
/// name of the field defined on the class.
class JsonKey {
  final String jsonName;
  const JsonKey(this.jsonName);
}
