/// The demo account's data: a made-up student with five courses this
/// semester, answering every eCourse2 request and campus page the app reads.
/// Dates are counted from today, so the demo always looks current. Nothing
/// here reaches the school.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'moodle_client.dart';

const demoName = '示範同學';

/// `115_1` for the semester [d] falls in (first term August to January).
String _semester(DateTime d) {
  final year = d.month >= 8 ? d.year - 1911 : d.year - 1912;
  final term = d.month >= 8 || d.month == 1 ? 1 : 2;
  return '${year}_$term';
}

String _previous(String semester) {
  final [year, term] = semester.split('_').map(int.parse).toList();
  return term == 2 ? '${year}_1' : '${year - 1}_2';
}

int _ts(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Each course: id, English and Chinese name, room, schedule, teacher.
const _courses = [
  (
    9001,
    'Software Analysis and Optimization軟體分析與最佳化',
    '創新大樓322',
    '週二 C,D',
    '林教授',
  ),
  (9002, 'Network Security網路安全攻防技術', '創新大樓324', '週二 E,F', '陳教授'),
  (
    9003,
    'Special Topics on Computer Science (III)計算機專題（三）',
    '創新大樓110',
    '週一 8,9',
    '王教授',
  ),
  (9004, 'Introduction to Deep Learning深度學習導論', '創新大樓341', '週四 B,C', '張教授'),
  (9005, 'Operating Systems作業系統', '工學院一館 102', '週三 3,4 週五 2', '李教授'),
];

/// Last semester's, for the semester menu and grades.
const _pastCourses = [(9101, 'Algorithms演算法'), (9102, 'Database Systems資料庫系統')];

/// Deadlines in days from today: course, kind, cmid, instance, name, days.
List<Map<String, Object?>> _deadlines() {
  Map<String, Object?> e(
    int course,
    String module,
    int cmid,
    int instance,
    String name,
    DateTime due,
  ) => {
    'name': name,
    'activityname': name,
    'modulename': module,
    'eventtype': module == 'quiz' ? 'close' : 'due',
    'instance': instance,
    'course': {
      'id': course,
      'fullname': _courses.firstWhere((c) => c.$1 == course).$2,
    },
    'timesort': _ts(due),
    'timestart': _ts(due),
    'url': 'https://ecourse2.ccu.edu.tw/mod/$module/view.php?id=$cmid',
  };
  final t = _today;
  return [
    e(
      9004,
      'quiz',
      90041,
      601,
      '小考二：反向傳播',
      t.add(const Duration(days: 1, hours: 10)),
    ),
    e(
      9001,
      'assign',
      90011,
      501,
      '作業三：資料流分析',
      t.add(const Duration(days: 2, hours: 23, minutes: 59)),
    ),
    e(
      9002,
      'assign',
      90021,
      502,
      'Lab 4 報告',
      t.add(const Duration(days: 5, hours: 23, minutes: 59)),
    ),
    e(
      9005,
      'assign',
      90051,
      503,
      '作業二：排程模擬',
      t.add(const Duration(days: 9, hours: 23, minutes: 59)),
    ),
  ];
}

Map<String, Object?> _file(String name, int size) => {
  'type': 'file',
  'filename': name,
  'filesize': size,
  'fileurl':
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
  'timemodified': _ts(_today.subtract(const Duration(days: 20))),
};

Map<String, Object?> _module(
  int id,
  int instance,
  String name,
  String modname, {
  List<Map<String, Object?>> files = const [],
  DateTime? due,
}) => {
  'id': id,
  'instance': instance,
  'name': name,
  'modname': modname,
  'url': null,
  'contents': files,
  'dates': [
    if (due != null) {'dataid': 'duedate', 'timestamp': _ts(due)},
  ],
};

/// Every course has the same 一般 section; 軟分 has more weeks.
List<Map<String, Object?>> _contents(int course) {
  final due = {
    for (final d in _deadlines())
      ((d['course'] as Map)['id'], d['instance']):
          DateTime.fromMillisecondsSinceEpoch((d['timesort'] as int) * 1000),
  };
  final general = {
    'name': '一般',
    'modules': [
      _module(course * 100, course * 10 + 1, '公佈欄Announcement', 'forum'),
      _module(course * 100 + 2, course * 10 + 3, '出缺席Attendance', 'attendance'),
      _module(course * 100 + 4, course * 10 + 5, 'General forum綜合討論區', 'forum'),
      _module(course * 100 + 6, course * 10 + 7, '請假單', 'absenceform'),
    ],
  };
  return switch (course) {
    9001 => [
      general,
      {
        'name': '第 1 週　課程介紹',
        'modules': [
          _module(
            90015,
            801,
            '課程大綱',
            'resource',
            files: [_file('syllabus.pdf', 182000)],
          ),
          _module(
            90016,
            802,
            '投影片：程式分析概論',
            'resource',
            files: [_file('week1.pdf', 2450000)],
          ),
        ],
      },
      {
        'name': '第 7 週　資料流分析',
        'modules': [
          _module(
            90017,
            803,
            '投影片：資料流分析',
            'resource',
            files: [_file('week7.pdf', 3120000)],
          ),
          _module(90011, 501, '作業三：資料流分析', 'assign', due: due[(9001, 501)]),
        ],
      },
    ],
    9002 => [
      general,
      {
        'name': '實驗',
        'modules': [
          _module(90021, 502, 'Lab 4 報告', 'assign', due: due[(9002, 502)]),
        ],
      },
    ],
    9004 => [
      general,
      {
        'name': '小考',
        'modules': [
          _module(90041, 601, '小考二：反向傳播', 'quiz', due: due[(9004, 601)]),
        ],
      },
    ],
    9005 => [
      general,
      {
        'name': '作業',
        'modules': [
          _module(90051, 503, '作業二：排程模擬', 'assign', due: due[(9005, 503)]),
        ],
      },
    ],
    _ => [general],
  };
}

/// Discussion ids are the forum id times ten plus a count.
List<Map<String, Object?>> _discussions(int forum) {
  final news = forum % 10 == 1;
  final t = _today;
  Map<String, Object?> d(
    int n,
    String subject,
    String who,
    int daysAgo,
    String body,
    int replies, {
    bool pinned = false,
  }) => {
    'id': forum * 100 + n,
    'discussion': forum * 10 + n,
    'name': subject,
    'subject': subject,
    'userfullname': who,
    'created': _ts(t.subtract(Duration(days: daysAgo))),
    'timemodified': _ts(t.subtract(Duration(days: daysAgo, hours: -9))),
    'message': '<p>$body</p>',
    'numreplies': replies,
    'pinned': pinned,
  };
  return news
      ? [
          d(
            1,
            '期中考範圍與考場公告',
            '授課教師',
            2,
            '期中考範圍為第 1 到 6 章，考場在原教室，請攜帶學生證。',
            0,
            pinned: true,
          ),
          d(
            2,
            '作業說明補充',
            '助教',
            5,
            '作業的輸入格式有更新，請下載新版的 starter code，舊版測資週五移除。',
            3,
          ),
          d(3, '停課一次', '授課教師', 6, '因學術研討會停課一次，補課時間另行公告。', 0),
        ]
      : [d(1, '期末專題分組', '同學', 3, '還缺一位組員，有興趣的同學請回覆。', 2)];
}

List<Map<String, Object?>> _posts(int discussion) {
  final t = DateTime.now().subtract(const Duration(days: 4));
  Map<String, Object?> p(
    int id,
    int parent,
    String who,
    int hours,
    String subject,
    String body,
  ) => {
    'id': id,
    'parentid': parent,
    'subject': subject,
    'message': '<p>$body</p>',
    'timecreated': _ts(t.add(Duration(hours: hours))),
    'author': {'fullname': who},
    'attachments': id == discussion * 10 ? [_file('補充說明.pdf', 184000)] : [],
  };
  final first = discussion * 10;
  return [
    p(first, 0, '助教', 0, '說明補充', '輸入格式改用 JSON 描述每個基本區塊，請下載新版的 starter code。'),
    p(first + 1, first, '同學', 12, 'Re: 說明補充', '請問舊版已經寫好的部分需要重寫嗎？'),
    p(first + 2, first + 1, '助教', 13, 'Re: 說明補充', '只要改讀檔的部分，分析邏輯不用動。'),
  ];
}

/// Answers every eCourse2 function the app calls, without the network.
class DemoMoodleClient extends MoodleClient {
  DemoMoodleClient()
    : super(siteUrl: Uri.parse('https://ecourse2.ccu.edu.tw/'), token: 'demo');

  /// Saved answers are the live ones: there is nothing to wait for.
  @override
  MoodleClient offline() => this;

  @override
  Future<dynamic> call(
    String function, [
    Map<String, Object?> params = const {},
  ]) async {
    final now = DateTime.now();
    final semester = _semester(now);
    int id(String key) => int.parse('${flattenParams(params)[key]}');
    return switch (function) {
      'core_webservice_get_site_info' => {'userid': 1, 'fullname': demoName},
      'core_enrol_get_users_courses' => [
        for (final c in _courses) {'id': c.$1},
        for (final c in _pastCourses) {'id': c.$1},
      ],
      'core_course_get_courses_by_field' => {
        'courses': [
          for (final (i, name, room, schedule, teacher) in _courses)
            {
              'id': i,
              'shortname': '${semester}_${4100000 + i}_01',
              'fullname': name,
              'contacts': [
                {'fullname': teacher},
              ],
              'customfields': [
                {'shortname': 'schedule', 'value': schedule},
                {'shortname': 'room', 'value': room},
              ],
            },
          for (final (i, name) in _pastCourses)
            {
              'id': i,
              'shortname': '${_previous(semester)}_${4100000 + i}_01',
              'fullname': name,
            },
        ],
      },
      'core_calendar_get_action_events_by_timesort' => {
        'events': [
          for (final e in _deadlines())
            if ((e['timesort'] as int) >= id('timesortfrom') &&
                (e['timesort'] as int) <= id('timesortto'))
              e,
        ],
      },
      'core_calendar_get_calendar_monthly_view' => {
        'weeks': [
          {
            'days': [
              {
                'events': [
                  for (final e in _deadlines())
                    if (DateTime.fromMillisecondsSinceEpoch(
                          (e['timesort'] as int) * 1000,
                        )
                        case final d
                        when d.year == id('year') && d.month == id('month'))
                      e,
                ],
              },
            ],
          },
        ],
      },
      'message_popup_get_unread_popup_notification_count' => 2,
      'message_popup_get_popup_notifications' => {
        'notifications': [
          for (final (i, subject, text, read) in [
            (1, '作業三：資料流分析 即將截止', '軟體分析與最佳化的作業三將在 2 天後截止。', false),
            (2, '期中考範圍與考場公告', '網路安全攻防技術有一則新公告。', false),
            (3, 'Lab 3 已評分', '網路安全攻防技術的 Lab 3 已經有成績。', true),
            (4, '小考一 已評分', '深度學習導論的小考一已經有成績。', true),
          ])
            {
              'subject': subject,
              'smallmessage': text,
              'timecreated': _ts(now.subtract(Duration(hours: i * 7))),
              'read': read,
              'contexturl': null,
            },
        ],
      },
      'local_mail_get_unread_count' => 1,
      'local_mail_get_index' => {
        'messages': [
          {
            'subject': '專題進度會議時間',
            'sender': {'fullname': '王教授'},
            'course': {'shortname': '$semester 計算機專題（三）'},
            'time': _ts(now.subtract(const Duration(hours: 5))),
            'unread': true,
          },
          {
            'subject': 'Lab 4 繳交方式',
            'sender': {'fullname': '助教'},
            'course': {'shortname': '$semester 網路安全攻防技術'},
            'time': _ts(now.subtract(const Duration(days: 3))),
            'unread': false,
          },
        ],
      },
      'core_course_get_contents' => _contents(id('courseid')),
      'mod_forum_get_forums_by_courses' => [
        {'id': id('courseids[0]') * 10 + 1, 'type': 'news'},
        {'id': id('courseids[0]') * 10 + 5, 'type': 'general'},
      ],
      'mod_forum_get_forum_discussions' => {
        'discussions': _discussions(id('forumid')),
      },
      'mod_forum_get_discussion_posts' => {'posts': _posts(id('discussionid'))},
      'gradereport_overview_get_course_grades' => {
        'grades': [
          {'courseid': 9001, 'grade': '88.50'},
          {'courseid': 9002, 'grade': '92.00'},
          {'courseid': 9003, 'grade': '-'},
          {'courseid': 9004, 'grade': '80.17'},
          {'courseid': 9005, 'grade': '76.00'},
          {'courseid': 9101, 'grade': '91.00'},
          {'courseid': 9102, 'grade': '85.00'},
        ],
      },
      'gradereport_user_get_grade_items' => {
        'usergrades': [
          {
            'gradeitems': [
              for (final (name, grade, percent) in [
                ('作業一', '95.00', '95.00 %'),
                ('作業二', '82.00', '82.00 %'),
                ('期中考', '88.00', '88.00 %'),
                ('作業三', '-', '-'),
              ])
                {
                  'itemtype': 'mod',
                  'itemname': name,
                  'gradeformatted': grade,
                  'percentageformatted': percent,
                },
            ],
          },
        ],
      },
      'mod_assign_get_assignments' => {
        'courses': [
          {
            'assignments': [
              for (final e in _deadlines())
                if (e['modulename'] == 'assign')
                  {
                    'id': e['instance'],
                    'intro': '<p>依照講義的格式完成，並上傳 PDF 與程式碼壓縮檔。</p>',
                    'introattachments': [_file('說明.pdf', 98000)],
                    'allowsubmissionsfromdate': _ts(
                      _today.subtract(const Duration(days: 7)),
                    ),
                    'duedate': e['timesort'],
                  },
            ],
          },
        ],
      },
      'mod_assign_get_submission_status' => {
        'lastattempt': {
          'submission': {'status': 'new'},
        },
      },
      'mod_quiz_get_quizzes_by_courses' => {
        'quizzes': [
          {
            'id': 601,
            'intro': '<p>範圍：第 4 到 5 章，限時 30 分鐘。</p>',
            'timeopen': _ts(_today),
            'timeclose': _ts(_today.add(const Duration(days: 1, hours: 10))),
            'attempts': 1,
            'grade': 100,
          },
        ],
      },
      'mod_quiz_get_user_attempts' => {'attempts': []},
      'mod_quiz_get_user_best_grade' => {'hasgrade': false, 'gradetopass': 60},
      _ => throw MoodleException('demo', function),
    };
  }
}

/// Campus pages for the demo account, in the shape each page's script
/// answers with.
abstract final class DemoCampus {
  static String _roc(DateTime d) =>
      '${d.year - 1911}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  static String _ymd(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> payments(int year) {
    final now = DateTime.now();
    Map<String, dynamic> row(
      int month,
      int day,
      String amount,
      String note,
    ) => {
      'expreg_no': 'A${year}0$month$day',
      'expreg_seri_cd': '1',
      'reg_status_name': '已付款',
      'pay_date':
          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
      'pay_amt': amount,
      'bank_acc_no': '000123456789012',
      'invoice_no': '',
      'c_name': '承辦人',
      'unit_name': '資訊工程學系',
      'purp_note': note,
    };
    final months = year == now.year - 1911 ? now.month : 12;
    return {
      'year': year,
      'rows': [
        for (var m = 2; m <= months; m += 2)
          row(m, 10, '\$${3000 + m * 250}', '教學助理工讀金'),
        if (months >= 9) row(9, 25, '\$2,000', '研究計畫臨時工資'),
      ],
      'years': ['${year - 1}', '${year - 2}'],
      'income': {
        '${year - 1}': [
          {
            'incoming_no': '50',
            'pro_cd': 'A000000000',
            'in_amt_total': '\$36,500',
            'tax_amt_total': '\$0',
            'net_amt_total': '\$36,500',
            'labor_save_amt_total': '\$0',
          },
        ],
        '${year - 2}': [
          {
            'incoming_no': '50',
            'pro_cd': 'A000000000',
            'in_amt_total': '\$18,000',
            'tax_amt_total': '\$0',
            'net_amt_total': '\$18,000',
            'labor_save_amt_total': '\$0',
          },
        ],
      },
    };
  }

  static Map<String, dynamic> library() {
    final t = DateTime.now();
    return {
      'loans': [
        {
          'loanid': 'L1',
          'title': '深度學習',
          'author': 'Goodfellow, Ian',
          'duedate': _ymd(t.add(const Duration(days: 5))),
          'renewable': 'Y',
        },
        {
          'loanid': 'L2',
          'title': '作業系統概念',
          'author': 'Silberschatz, Abraham',
          'duedate': _ymd(t.add(const Duration(days: 12))),
          'renewable': 'Y',
        },
      ],
      'holds': [
        {
          'requestid': 'R1',
          'requesttype': 'HOLD',
          'title': '編譯器設計',
          'requeststatus': 'On Hold Shelf',
          'pickuplocation': '總圖書館',
          'expirydate': _ymd(t.add(const Duration(days: 4))),
        },
      ],
    };
  }

  static Map<String, dynamic> leave() {
    final t = DateTime.now();
    return {
      'rows': [
        [
          'L0001',
          '病假',
          _roc(t.subtract(const Duration(days: 20))),
          '已送出',
          '核准',
        ],
        ['L0002', '事假', _roc(t.add(const Duration(days: 3))), '已送出', '審核中'],
      ],
    };
  }

  static Map<String, dynamic> iccu() => {
    'data': {
      '/b04/b04250': [
        [
          for (final (name, time, room, teacher, credit) in [
            ('軟體分析與最佳化', '二 C,D', '創新大樓322', '林教授', '3'),
            ('網路安全攻防技術', '二 E,F', '創新大樓324', '陳教授', '3'),
            ('計算機專題（三）', '一 8,9', '創新大樓110', '王教授', '2'),
            ('深度學習導論', '四 B,C', '創新大樓341', '張教授', '3'),
            ('作業系統', '三 3,4 五 2', '工學院一館 102', '李教授', '3'),
          ])
            {
              'SemesterCourseName': name,
              'SemCourseTime': time,
              'ClassRoom': room,
              'Teacher': teacher,
              'IsStopName': '正常開課',
              'ChooseName': '選修',
              'Credit': credit,
            },
        ],
      ],
    },
    'open': <String, bool>{},
  };

  static Map<String, dynamic> attendance() {
    final rows = <List<String>>[];
    final t = DateTime.now();
    for (var w = 6; w >= -3; w--) {
      final d = t.subtract(Duration(days: w * 7));
      final date =
          '${d.year}年${d.month}月${d.day}日 (週${'一二三四五六日'[d.weekday - 1]}) 10:15AM - 1點PM';
      rows.add(
        w <= 0
            ? [date, '一般上課', '?', '? / 2', '']
            : w == 4
            ? [date, '一般上課', '遲到Late', '1 / 2', '']
            : [date, '一般上課', '出席Present', '2 / 2', '自行紀錄的'],
      );
    }
    return {
      'kind': 'attendance',
      'rows': rows,
      'summary': [
        ['已記錄的上課時段:', '6'],
        ['出席次數的分數:', '11 / 12'],
        ['出席次數百分比:', '91.7%'],
      ],
    };
  }

  static Map<String, dynamic> absences() => {
    'kind': 'absences',
    'head': ['請假日期', '請假類型', '課程類型', '備註'],
    'rows': [
      [
        _roc(DateTime.now().subtract(const Duration(days: 14))),
        '病假',
        '面授',
        '發燒就醫',
      ],
    ],
    'course': '軟體分析與最佳化',
  };

  static Map<String, dynamic> academic() => {
    'kind': 'detail',
    'studentNo': '412000000',
    'englishName': 'DEMO STUDENT',
    'email': 'demo@ccu.edu.tw',
    'mobile': '0900-000-000',
  };

  static Map<String, dynamic> myEvents() => {
    'mine': <Map>[],
    'past': [
      {'id': 'demo1', 'title': '期中考前讀書技巧講座'},
      {'id': 'demo2', 'title': '圖書館資料庫利用課程'},
    ],
    'attended': 2,
    'hours': '4',
  };

  static Map<String, dynamic> space() => {
    'auth': {'sid': 'demo', 'userid': 'demo', 'authid': 'demo'},
    'kinds': [
      {'type': '1', 'name': '自學座位', 'floor': '5F'},
      {'type': '2', 'name': '討論室', 'floor': '3F'},
    ],
    'open': '08:00–22:00',
    'refresh': 180,
    'interval': 30,
  };

  /// The space API's answers: a door code and the free places.
  static Map<String, dynamic> spaceApi(String path) => switch (path) {
    'GetQRCode.aspx' => {
      'rescode': '1',
      'resdata': [
        {'qrcode': 'data:image/png;base64,${_base64(_demoCode())}'},
      ],
    },
    _ => {
      'rows': [
        {'spacetype': '1', 'count': 42, 'name': '5L'},
        {'spacetype': '2', 'count': 3, 'name': '301'},
      ],
    },
  };

  static String _base64(Uint8List bytes) => const Base64Codec().encode(bytes);

  /// A QR-looking grayscale PNG: finder squares in three corners and a
  /// fixed pattern between, drawn 8 px per module.
  static Uint8List _demoCode() {
    const modules = 25, scale = 8, size = modules * scale;
    bool dark(int x, int y) {
      bool finder(int ox, int oy) {
        final dx = x - ox, dy = y - oy;
        if (dx < 0 || dy < 0 || dx > 6 || dy > 6) return false;
        return dx == 0 ||
            dy == 0 ||
            dx == 6 ||
            dy == 6 ||
            (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
      }

      if (finder(0, 0) || finder(modules - 7, 0) || finder(0, modules - 7)) {
        return true;
      }
      if ((x < 8 && y < 8) ||
          (x >= modules - 8 && y < 8) ||
          (x < 8 && y >= modules - 8)) {
        return false;
      }
      return (x * 7 + y * 13 + x * y) % 5 < 2;
    }

    final raw = BytesBuilder();
    for (var py = 0; py < size; py++) {
      raw.addByte(0); // No filter.
      for (var px = 0; px < size; px++) {
        raw.addByte(dark(px ~/ scale, py ~/ scale) ? 0 : 255);
      }
    }
    Uint8List chunk(String type, List<int> data) {
      final b = BytesBuilder()
        ..add(_u32(data.length))
        ..add(type.codeUnits)
        ..add(data)
        ..add(_u32(_crc([...type.codeUnits, ...data])));
      return b.toBytes();
    }

    final header = BytesBuilder()
      ..add(_u32(size))
      ..add(_u32(size))
      ..add([8, 0, 0, 0, 0]); // 8-bit grayscale.
    return (BytesBuilder()
          ..add([137, 80, 78, 71, 13, 10, 26, 10])
          ..add(chunk('IHDR', header.toBytes()))
          ..add(chunk('IDAT', ZLibCodec().encode(raw.toBytes())))
          ..add(chunk('IEND', const [])))
        .toBytes();
  }

  static List<int> _u32(int v) => [
    v >> 24 & 255,
    v >> 16 & 255,
    v >> 8 & 255,
    v & 255,
  ];

  static int _crc(List<int> bytes) {
    var c = 0xffffffff;
    for (final b in bytes) {
      c ^= b;
      for (var k = 0; k < 8; k++) {
        c = c & 1 != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1;
      }
    }
    return c ^ 0xffffffff;
  }
}
