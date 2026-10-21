import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/html_text.dart';

void main() {
  test('character references are decoded', () {
    expect(plainText('A&#65;&#x42;&amp;'), 'AAB&');
  });

  // One bad reference in a post must not fail the whole forum.
  test('a malformed or out-of-range reference stays as written', () {
    expect(plainText('a&#12a;b'), 'a&#12a;b');
    expect(plainText('&#x110000;'), '&#x110000;');
  });
}
