/// An error which occurred during source generation. These are typically errors
/// that were internally detected.
class SourceGenError extends Error {
  final String _message;

  SourceGenError(this._message);

  @override
  String toString() => 'SourceGenError: $_message';
}
