// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String normalizeBuilderKeyDefinition(String builderKey, String packageName) {
  if (builderKey.startsWith('|')) return '$packageName$builderKey';
  if (!builderKey.contains('|')) return '$packageName|$builderKey';
  return builderKey;
}

String normalizeBuilderKeyUsage(String builderKey, String packageName) {
  if (builderKey.startsWith('|')) return '$packageName$builderKey';
  if (!builderKey.contains('|')) return '$builderKey|$builderKey';
  return builderKey;
}

String normalizeTargetKeyDefinition(String targetKey, String packageName) {
  if (targetKey.startsWith(':')) return '$packageName$targetKey';
  if (!targetKey.contains(':')) return '$packageName:$targetKey';
  return targetKey;
}

String normalizeTargetKeyUsage(String targetKey, String packageName) {
  if (targetKey.startsWith(':')) return '$packageName$targetKey';
  if (!targetKey.contains(':')) return '$targetKey:$targetKey';
  return targetKey;
}
