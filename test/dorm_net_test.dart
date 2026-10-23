import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/dorm_net_data.dart';
import 'package:tat_ccu/data/services/html_text.dart';

void main() {
  test('a paid term reads its bed, state and breaks in site labels', () {
    final d = dormNetOf({
      'usage': 23.4,
      'semesters': [
        {
          'academic_year': '115',
          'semester': 'fall',
          'data': {
            'state': 'paid',
            'keystone': {'type': 'undergrad', 'room': 'C312', 'bed': '2'},
          },
        },
      ],
      'labels': {'paid': '已繳費', 'fall': '上學期', 'disabled.virus': '中毒斷線'},
      'breaks': [
        {
          'type': 'virus',
          'suspended_at': '2026-03-12T21:40:00',
          'unsuspended_at': null,
        },
      ],
      'status': {'suspended': false},
      'cards': [
        {'mac': '3C:22:FB:9A:10:41'},
        {'mac': ''},
      ],
      'wifi': 1,
    });
    expect(d.usage, 23.4);
    expect(d.term, '115 上學期');
    expect(d.state, '已繳費');
    expect(d.bed, 'C312-2');
    expect(d.applied, isTrue);
    expect(d.suspended, isNull);
    expect(d.breaks.single.kind, '中毒斷線');
    expect(d.breaks.single.until, isNull);
    expect(d.cards, ['3C:22:FB:9A:10:41']);
  });

  test('no application this term keeps the last bed', () {
    final d = dormNetOf({
      'semesters': [
        {'academic_year': '115', 'semester': 'fall', 'data': null},
      ],
      'lastBed': {'type': 'undergrad', 'room': 'C312', 'bed': '2'},
    });
    expect(d.applied, isFalse);
    expect(d.bed, isNull);
    expect(d.lastBed, 'C312-2');
  });

  test('a suspension names its reason, from the status or the dashboard', () {
    const labels = {'disabled.virus': '中毒斷線'};
    expect(
      dormNetOf({
        'labels': labels,
        'status': {'suspended': true, 'reason': 'virus'},
      }).suspended,
      '中毒斷線',
    );
    expect(
      dormNetOf({'labels': labels, 'disabling': 'virus'}).suspended,
      '中毒斷線',
    );
  });

  test('the fee row follows the month into each term', () {
    expect(dormNetFeeRow(DateTime(2026, 9, 1)), (fall: true, row: 0));
    expect(dormNetFeeRow(DateTime(2026, 11, 30)), (fall: true, row: 1));
    expect(dormNetFeeRow(DateTime(2027, 1, 5)), (fall: true, row: 3));
    expect(dormNetFeeRow(DateTime(2027, 3, 31)), (fall: false, row: 0));
    expect(dormNetFeeRow(DateTime(2027, 7, 1)), (fall: false, row: 3));
  });

  test('offices read their hours and notes from the site text', () {
    final c = dormNetOfficeOf(
      plainText(
        '<h3 class="ql-align-center">大學部 C 棟 B1 (#73199)</h3>'
        '<p class="ql-align-center">週一至週五 19:00 - 22:00</p>'
        '<p class="ql-align-center"><br></p>',
      ),
    );
    expect(c.name, '大學部 C 棟 B1');
    expect(c.ext, '73199');
    expect(c.hours, '週一至週五 19:00 - 22:00');
    expect(c.closedFirst, isFalse);
    final it = dormNetOfficeOf(
      plainText(
        '<h3>資訊處 219 (#14151)</h3><p>週一至週五 '
        '<span style="color: rgb(98, 98, 98);">13:00 - 16:00</span></p>'
        '<p>&nbsp;<strong>每月一號, 周末及假日不開放</strong></p>',
      ),
    );
    expect(it.hours, '週一至週五 13:00 - 16:00');
    expect((it.from, it.to), (13 * 60, 16 * 60));
    expect(it.closedFirst, isTrue);

    // 2026-10-23 is a Friday.
    expect(dormNetOfficeOpen(DateTime(2026, 10, 23, 19), c), isTrue);
    expect(dormNetOfficeOpen(DateTime(2026, 10, 23, 22), c), isFalse);
    expect(dormNetOfficeOpen(DateTime(2026, 10, 24, 20), c), isFalse);
    expect(dormNetOfficeOpen(DateTime(2026, 10, 1, 20), c), isTrue);
    expect(dormNetOfficeOpen(DateTime(2026, 10, 1, 14), it), isFalse);
    expect(dormNetOfficeOpen(DateTime(2026, 10, 2, 14), it), isTrue);
  });

  test('virus penalties grow from the third, up to 14 days', () {
    expect(
      [for (var n = 1; n <= 6; n++) dormNetPenaltyDays(n)],
      [1, 1, 2, 3, 4, 5],
    );
    expect(dormNetPenaltyDays(30), 14);
  });

  test('a closed office names when it next opens, past the 1st', () {
    final it = dormNetOfficeOf(
      '資訊處 219 (#14151)\n週一至週五 13:00 - 16:00\n每月一號不開放',
    );
    // Friday after hours: Monday 13:00.
    expect(
      dormNetOfficeNext(DateTime(2026, 10, 23, 17), it),
      DateTime(2026, 10, 26, 13),
    );
    // Friday 5/29 after hours: Monday 6/1 is the 1st, so Tuesday.
    expect(
      dormNetOfficeNext(DateTime(2026, 5, 29, 17), it),
      DateTime(2026, 6, 2, 13),
    );
  });
}
