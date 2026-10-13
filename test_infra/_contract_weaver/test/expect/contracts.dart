// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The annotation library, as a package declares it. Weaving it adds the
// runtime support.

class Requires {
  final String clause;
  const Requires(this.clause);
}

class Ensures {
  final String clause;
  const Ensures(this.clause);
}

class ThrowEnsures {
  final Type type;
  final String clause;
  const ThrowEnsures(this.type, this.clause);
}

class Invariant {
  final String clause;
  const Invariant(this.clause);
}

class ContractImport {
  final String uri;
  const ContractImport(this.uri);
}
