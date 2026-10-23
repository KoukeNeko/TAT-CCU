<?php
// Fills a fresh test site with what the app reads: a student and a teacher,
// two courses this semester and one last semester, forums, an assignment, a
// quiz, grades, mail and an attendance session with a QR code. Turns on the
// web services the Moodle app (and TAT CCU) signs in through.
//
//   php /var/www/tatccu-seed.php
//
// Prints the fixture ids as JSON for the tests (test/moodle_site).

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');
require_once($CFG->libdir . '/testing/generator/lib.php');
require_once($CFG->dirroot . '/mod/attendance/locallib.php');

const PASSWORD = 'Test1234!';

// Draft files and events need someone signed in.
\core\session\manager::set_user(get_admin());

// eCourse2's interface language, set before anything names itself.
set_config('lang', 'zh_tw');
force_current_language('zh_tw');

// The mobile web service, as eCourse2 has it on.
set_config('enablewebservices', 1);
set_config('webserviceprotocols', 'rest');
set_config('enablemobilewebservice', 1);
$DB->set_field('external_services', 'enabled', 1, ['shortname' => 'moodle_mobile_app']);
// Plain passwords for the fixture accounts.
set_config('passwordpolicy', 0);

$gen = new testing_data_generator();
$now = time();

// Semesters as the app names them: ROC year and term, 115_1 from August.
function semester(int $time): string {
    [$year, $month] = array_map('intval', explode(' ', date('Y n', $time)));
    $roc = $month >= 8 ? $year - 1911 : $year - 1912;
    $term = $month >= 8 || $month == 1 ? 1 : 2;
    return "{$roc}_{$term}";
}
$current = semester($now);
$previous = semester($now - 183 * DAYSECS);

$student = $gen->create_user([
    'username' => 'student', 'password' => PASSWORD,
    'firstname' => '同學', 'lastname' => '測試', 'email' => 'student@example.com',
]);
$teacher = $gen->create_user([
    'username' => 'teacher', 'password' => PASSWORD,
    'firstname' => '教授', 'lastname' => '王', 'email' => 'teacher@example.com',
]);

// eCourse2 keeps the timetable in two course custom fields.
$category = $gen->create_custom_field_category(['component' => 'core_course', 'area' => 'course', 'name' => '課程資訊']);
foreach (['schedule' => '上課時間', 'room' => '教室'] as $shortname => $name) {
    $gen->create_custom_field(['categoryid' => $category->get('id'), 'type' => 'text', 'shortname' => $shortname, 'name' => $name]);
}

$courses = [];
foreach ([
    ["{$current}_4101001_01", 'Software Analysis and Optimization軟體分析與最佳化', '週二 C,D', '創新大樓322'],
    ["{$current}_4101002_01", 'Network Security網路安全攻防技術', '週四 E,F', '創新大樓324'],
    ["{$previous}_4101101_01", 'Algorithms演算法', '', ''],
] as [$shortname, $fullname, $schedule, $room]) {
    $course = $gen->create_course([
        'shortname' => $shortname, 'fullname' => $fullname, 'numsections' => 3,
        'customfield_schedule' => $schedule, 'customfield_room' => $room,
    ]);
    $gen->enrol_user($student->id, $course->id, 'student');
    $gen->enrol_user($teacher->id, $course->id, 'editingteacher');
    $courses[] = $course;
}
[$course, $other] = $courses;

$forums = $gen->get_plugin_generator('mod_forum');
$news = $gen->create_module('forum', ['course' => $course->id, 'type' => 'news', 'name' => '課程公告']);
$forums->create_discussion([
    'course' => $course->id, 'forum' => $news->id, 'userid' => $teacher->id,
    'name' => '期中考範圍', 'message' => '<p>期中考範圍為第一到第六章。</p>',
]);
$forum = $gen->create_module('forum', ['course' => $course->id, 'type' => 'general', 'name' => '課程討論區']);
$discussion = $forums->create_discussion([
    'course' => $course->id, 'forum' => $forum->id, 'userid' => $teacher->id,
    'name' => '作業一問題討論', 'message' => '<p>作業一有問題請在這裡發問。</p>',
]);

$assign = $gen->create_module('assign', [
    'course' => $course->id, 'name' => '作業一：效能分析',
    'duedate' => $now + 3 * DAYSECS, 'allowsubmissionsfromdate' => $now - DAYSECS,
    'assignsubmission_onlinetext_enabled' => 1,
    'assignsubmission_comments_enabled' => 1,
]);
set_config('enabled', 1, 'assignsubmission_comments');
$gen->create_module('quiz', [
    'course' => $other->id, 'name' => '小考一',
    'timeopen' => $now - DAYSECS, 'timeclose' => $now + 5 * DAYSECS,
]);

// The student's submission, which submission comments hang off.
require_once($CFG->dirroot . '/mod/assign/locallib.php');
$assignment = new assign(context_module::instance($assign->cmid), null, null);
$submission = $assignment->get_user_submission($student->id, true);

$item = $gen->create_grade_item(['courseid' => $course->id, 'itemname' => '期中考', 'grademax' => 100]);
$gen->create_grade_grade(['itemid' => $item->id, 'userid' => $student->id, 'finalgrade' => 88]);

// eCourse2 names each status in both languages, which the app splits.
foreach (['P' => '出席Present', 'A' => '缺席Absent', 'L' => '遲到Late', 'E' => '請假Excused'] as $acronym => $name) {
    $DB->set_field('attendance_statuses', 'description', $name, ['attendanceid' => 0, 'acronym' => $acronym]);
}
$attendance = $gen->create_module('attendance', ['course' => $course->id, 'name' => '點名']);
$cm = get_coursemodule_from_instance('attendance', $attendance->id);
$structure = new mod_attendance_structure($attendance, $cm, $course, context_module::instance($cm->id));
// Open now, scanned with a fixed password; the status is set by itself.
$qrpass = 'tatccu-qr';
$sessid = $structure->add_session((object) [
    'sessdate' => $now - HOURSECS, 'duration' => 3 * HOURSECS, 'groupid' => 0,
    'description' => '第八週', 'descriptionitemid' => 0, 'descriptionformat' => FORMAT_HTML,
    'timemodified' => $now, 'statusset' => 0, 'studentscanmark' => 1,
    'autoassignstatus' => 1, 'studentpassword' => $qrpass, 'includeqrcode' => 1,
    'rotateqrcode' => 0, 'rotateqrcodesecret' => '', 'allowupdatestatus' => 0,
    'calendarevent' => 0, 'absenteereport' => 1,
]);

require_once($CFG->dirroot . '/local/mail/message.class.php');
$message = local_mail_message::create($teacher->id, $course->id, $now);
$message->save('期中考教室異動', '<p>期中考改在創新大樓 110。</p>', FORMAT_HTML, 0, $now);
$message->add_recipient('to', $student->id);
$message->send($now);

echo json_encode([
    'site' => $CFG->wwwroot,
    'username' => 'student',
    'password' => PASSWORD,
    'courseId' => (int) $course->id,
    'forumId' => (int) $forum->id,
    'discussionId' => (int) $discussion->id,
    'assignCmid' => (int) $assign->cmid,
    'submissionId' => (int) $submission->id,
    'attendanceCmid' => (int) $cm->id,
    'attendanceUrl' => "{$CFG->wwwroot}/mod/attendance/attendance.php?qrpass={$qrpass}&sessid={$sessid}",
], JSON_UNESCAPED_SLASHES) . "\n";
