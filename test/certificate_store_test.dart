import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/repositories/certificate_store.dart';

void main() {
  test('semester follows the ROC academic year', () {
    expect(semesterOf(DateTime(2026, 10, 19)), '115-1');
    expect(semesterOf(DateTime(2027, 1, 20)), '115-1');
    expect(semesterOf(DateTime(2027, 2, 1)), '115-2');
    expect(semesterOf(DateTime(2027, 7, 31)), '115-2');
    expect(semesterOf(DateTime(2027, 8, 1)), '116-1');
  });
}
