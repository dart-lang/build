import 'package:checks/context.dart';

extension MapChecks<K, V> on Check<Map<K, V>> {
  void containsKey(K key) {
    context.expect(() => ['contains key ${literal(key)}'], (v) {
      if (v.containsKey(key)) return null;
      return Rejection(
          actual: literal(v), which: 'does not contain key ${literal(key)}');
    });
  }

  void deepEquals(Map<K, V> other) {
    // TODO
  }
}
