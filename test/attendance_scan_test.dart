import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/courses/attendance_scan_screen.dart';

void main() {
  test('only eCourse2 attendance links are opened', () {
    bool ok(String url) => isAttendanceLink(Uri.parse(url));
    expect(
      ok(
        'https://ecourse2.ccu.edu.tw/mod/attendance/attendance.php?qrpass=abc123&sessid=42',
      ),
      isTrue,
    );
    expect(
      ok('https://ecourse2.ccu.edu.tw/mod/attendance/attendance.php?sessid=x'),
      isFalse,
    );
    expect(
      ok('http://ecourse2.ccu.edu.tw/mod/attendance/attendance.php?sessid=42'),
      isFalse,
    );
    expect(
      ok('https://evil.example/mod/attendance/attendance.php?sessid=42'),
      isFalse,
    );
    expect(ok('https://ecourse2.ccu.edu.tw/login/logout.php'), isFalse);
  });
}
