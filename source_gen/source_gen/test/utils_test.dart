library source_gen.test.utils_test;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:source_gen/src/utils.dart';

void main() {
  test("thing", () {
    var index = findPartOf('''// commant
//more comment
part of foo;''');
    expect(index, 'part of foo;');
  });

  test('more thing', () {
    var index = findPartOf('''

// that two blank linse
// a comment line

// another blank line
part of monkey;
class bar{}''');
    expect(index, 'part of monkey;\nclass bar{}');
  });

  test("another", () {
    var index = findPartOf('//\n//\n\n');
    expect(index, null);
  });
}
