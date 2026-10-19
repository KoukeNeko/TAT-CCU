import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/data/services/ecourse_web.dart';

void main() {
  test('reads sessions and the course summary from view.php', () {
    final a = attendanceOf({
      'rows': [
        ['2026年10月20日 (週二) 10:15AM - 12點PM', '一般上課', '出席Present', '2 / 2', ''],
        ['2026年10月13日 (週二) 10:15AM - 12點PM', '一般上課', '遲到Late', '1 / 2', '塞車'],
        ['2026年11月2日 (週一) 1:30PM - 3點PM', '一般上課時段', '?', '? / 2', ''],
        ['沒有紀錄'],
      ],
      'summary': [
        ['已記錄的上課時段:', '7'],
        ['出席次數的分數:', '13 / 14'],
        ['出席次數百分比:', '92.9%'],
        ['上課時段總數:', '18'],
      ],
    });
    expect(a.sessions, hasLength(3));
    expect((a.sessions.last.status, a.sessions.last.points), ('', ''));
    expect(a.sessions.first.date, DateTime(2026, 10, 20));
    expect(a.sessions.first.time, '10:15AM - 12點PM');
    expect(a.sessions.map((s) => s.status), ['出席', '遲到', '']);
    expect(a.sessions[1].remark, '塞車');
    expect((a.taken, a.points, a.rate), ('7', '13 / 14', '92.9%'));
  });
}
