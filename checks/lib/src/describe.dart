String literal(Object? o) {
  if (o == null) return '<null>';
  if (o is num || o is bool) return '<$o>';
  // TODO Truncate long strings?
  if (o is String) return '\'$o\'';
  // TODO Truncate long collections?
  return '$o';
}

Iterable<String> indent(Iterable<String> lines) => lines.map((l) => '  $l');
