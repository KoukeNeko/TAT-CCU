import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/domain/models/course.dart';

void main() {
  test('courses get distinct color slots in enrollment order', () {
    final courses = [
      for (var i = 0; i < 4; i++)
        Course(id: 100 + i * 10, shortName: '115_1_$i', fullName: 'c$i'),
    ];
    assignCourseColors(courses);
    expect(courses.map((c) => courseColorSlot(c.id)), [0, 1, 2, 3]);
    expect(courseColorSlot(999), 999);
  });
}
