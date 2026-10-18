import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/repositories/ecourse_repository.dart';

void main() {
  test('multilang keeps the Traditional Chinese span', () {
    expect(
      multilang(
        '<span lang="zh_tw" class="multilang">出缺席</span>'
        '<span lang="en" class="multilang">Attendance</span>',
      ),
      '出缺席',
    );
    expect(multilang('gcov &amp; lcov'), 'gcov & lcov');
  });
}
