// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Weaves contract programming checks into a copy of Dart source.
///
/// The shape closely follows Cofoja, Contracts for Java. Contracts are written
/// as expression strings in annotations, and woven into a throwaway copy of the
/// source for runs that want them checked. Nothing is generated into the
/// repository and no dependency is added to the code under contract: the
/// annotations are matched by name, so each package declares its own.
library;

export 'src/contract_import_rule.dart' show ContractImportRule;
export 'src/contract_weaver.dart' show ContractWeaver;
