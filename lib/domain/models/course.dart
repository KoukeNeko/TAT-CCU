import 'timetable.dart';

class Course {
  const Course({
    required this.id,
    required this.shortName,
    required this.fullName,
    this.room,
    this.sessions = const [],
  });

  final int id;

  /// `學年_學期_課號_班別`, e.g. `115_1_4105402_01`.
  final String shortName;
  final String fullName;
  final String? room;
  final List<ClassSession> sessions;

  /// `115_1`, used to group courses by semester.
  String get semester => shortName.split('_').take(2).join('_');

  /// Builds a course from `core_course_get_courses_by_field`, where CCU keeps
  /// the timetable in the `schedule` and `room` custom fields.
  factory Course.fromMoodle(Map<String, dynamic> json) {
    String? field(String name) {
      for (final f in (json['customfields'] as List? ?? const [])) {
        if (f['shortname'] == name) return f['value'] as String?;
      }
      return null;
    }

    return Course(
      id: json['id'] as int,
      shortName: json['shortname'] as String,
      fullName: json['fullname'] as String,
      room: field('room'),
      sessions: parseSchedule(field('schedule') ?? ''),
    );
  }
}

/// Identity-color slot per course id, assigned in enrollment order (newest
/// semester first) so a student's courses get different colors before any
/// repeats. Unknown ids fall back to the id itself.
final _colorSlots = <int, int>{};

void assignCourseColors(List<Course> newestFirst) {
  _colorSlots
    ..clear()
    ..addAll({for (final (i, c) in newestFirst.indexed) c.id: i});
}

int courseColorSlot(int courseId) => _colorSlots[courseId] ?? courseId;

/// `115_1` → `115 學年上學期`.
String semesterLabel(String semester) {
  final parts = semester.split('_');
  if (parts.length < 2) return semester;
  final term = switch (parts[1]) {
    '1' => '上學期',
    '2' => '下學期',
    _ => '暑期',
  };
  return '${parts[0]} 學年$term';
}

/// `115_1` → `115-1`, for tight spots like the app bar.
String semesterShort(String semester) => semester.replaceAll('_', '-');
