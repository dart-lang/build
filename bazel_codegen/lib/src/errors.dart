/// An error which occurred during code generation.
///
/// These are typically errors that were detected internally.
class CodegenError extends Error {
  final String _message;

  CodegenError(this._message);

  @override
  String toString() => 'CodegenError: $_message';
}
