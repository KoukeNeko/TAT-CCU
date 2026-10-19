import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/more/library_screen.dart';

void main() {
  test('loans read every due date format, most urgent first', () {
    final loans = loansOf({
      'loans': [
        {'title': 'B', 'author': 'b', 'duedate': '20261105'},
        {'title': 'A', 'author': 'a', 'duedate': '10/17/2026'},
        {'title': 'C', 'dueDate': '2026-10-22T23:59:00Z'},
        {'title': 'no date'},
      ],
    });
    expect(loans.map((l) => l.title), ['A', 'C', 'B']);
    expect(loans.first.due, DateTime(2026, 10, 17));
  });

  test('only holds on the pickup shelf count as ready', () {
    final holds = readyHoldsOf({
      'holds': [
        {'title': 'X', 'status': 'On Hold Shelf', 'expirydate': '20261024'},
        {'title': 'Y', 'status': 'In Process'},
      ],
    });
    expect(holds.single.title, 'X');
    expect(holds.single.until, DateTime(2026, 10, 24));
  });
}
