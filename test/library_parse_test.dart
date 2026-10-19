import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/more/library_screen.dart';

void main() {
  test('loans read every due date format, most urgent first', () {
    final loans = loansOf({
      'loans': [
        {'loanid': 'L2', 'title': 'B', 'duedate': '20261105', 'renewable': 'N'},
        {'title': 'A', 'author': 'a', 'duedate': '10/17/2026'},
        {'title': 'C', 'dueDate': '2026-10-22T23:59:00Z'},
        {'title': 'no date'},
      ],
    });
    expect(loans.map((l) => l.title), ['A', 'C', 'B']);
    expect(loans.first.due, DateTime(2026, 10, 17));
    expect((loans.last.id, loans.last.renewable), ('L2', false));
    expect(loans.first.renewable, true);
  });

  test('only holds on the pickup shelf count as ready', () {
    final holds = holdsOf({
      'holds': [
        {
          'requestid': 'R1',
          'requesttype': 'HOLD',
          'title': 'X',
          'requeststatus': 'On Hold Shelf',
          'expiryDate': '20261024',
        },
        {'title': 'Y', 'status': 'In Process'},
      ],
    });
    expect(holds.where((h) => h.ready).single.title, 'X');
    expect(holds.first.until, DateTime(2026, 10, 24));
    expect((holds.first.id, holds.first.type), ('R1', 'HOLD'));
  });
}
