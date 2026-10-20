/// Escapes [string] for use inside a single-quoted string literal.
String escapeString(String string) => string
    .replaceAll(r'\', r'\\')
    .replaceAll(r'$', r'\$')
    .replaceAll("'", r"\'")
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r');

/// Strips off any trailing `?`.
String stripNullabilitySuffix(String string) =>
    string.endsWith('?') ? string.substring(0, string.length - 1) : string;
