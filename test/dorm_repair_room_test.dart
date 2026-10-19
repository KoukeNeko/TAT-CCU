import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/more/dorm_repair_data.dart';

void main() {
  test('rooms take only the four forms the site lists', () {
    for (final ok in ['3316A', '1325', 'A301', '5108-1']) {
      expect(roomPattern.hasMatch(ok), isTrue, reason: ok);
    }
    for (final bad in ['3316AB', '331A', 'A30', '5108-', '5108-12']) {
      expect(roomPattern.hasMatch(bad), isFalse, reason: bad);
    }
  });
}
