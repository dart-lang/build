const String _base62Chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String _prefixForPhase(int phase) {
  var value = phase;
  var limit = 62;
  var length = 1;
  while (value >= limit) {
    value -= limit;
    limit *= 62;
    length++;
  }
  
  var result = '';
  for (var i = 0; i < length; i++) {
    result = _base62Chars[value % 62] + result;
    value ~/= 62;
  }
  
  return ('\$' * length) + result;
}

void main() {
  print('0: ${_prefixForPhase(0)}');
  print('61: ${_prefixForPhase(61)}');
  print('62: ${_prefixForPhase(62)}');
  print('63: ${_prefixForPhase(63)}');
  print('1000: ${_prefixForPhase(1000)}');
  print('3905: ${_prefixForPhase(3905)}');
  print('3906: ${_prefixForPhase(3906)}');
}
