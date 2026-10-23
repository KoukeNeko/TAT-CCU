/// 宿網申請 (student.dorm.ccu.edu.tw), the student-run CNA's Laravel +
/// Inertia site, read in a signed-in WebView: every page answers its props
/// as JSON to an `X-Inertia` request (research_notes/宿網申請探勘).
/// Announcements come from the public www.dorm.ccu.edu.tw API.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'html_text.dart';

const dormNetHost = 'student.dorm.ccu.edu.tw';
const dormNetHome = 'https://$dormNetHost/';

/// Signs in through the site's own 「一般生 SSO 登入」 link when the page
/// has no user, then reads the dashboard, disconnections, wired cards and
/// the last bed. The Wi-Fi edit link carries a one-time token, so it is not
/// kept.
const readDormNet = r'''
(async () => {
  const page = JSON.parse(document.querySelector('#app')?.dataset.page || '{}');
  if (!page.props?.auth?.user) {
    // A sign-in hand-off page (/ssoStore) has no app and moves on by itself;
    // the script runs again on the page it lands on.
    if (!document.querySelector('#app')) return;
    // The welcome page draws its links after loading.
    for (let i = 0; i < 20; i++) {
      const sso = [...document.querySelectorAll('a')].find(a => a.href.includes('portal.dorm.ccu.edu.tw/sso.php'));
      if (sso) { location.href = sso.href; return; }
      await new Promise(done => setTimeout(done, 250));
    }
    throw new Error('DormNet sign-in link not found at ' + location.pathname);
  }
  // Read one at a time, each checked to be JSON: right after signing in the
  // site can still answer a read with a web page while the session settles,
  // so a page gets one more try before it counts as an error.
  const read = async (path, inertia) => {
    const r = await fetch(path, { credentials: 'same-origin', headers: inertia
      ? { 'X-Inertia': 'true', 'X-Inertia-Version': page.version, 'X-Requested-With': 'XMLHttpRequest' }
      : { Accept: 'application/json' } });
    if (!r.ok) throw new Error(path + ' ' + r.status);
    if (!(r.headers.get('content-type') || '').includes('json')) {
      const at = r.redirected ? ' at ' + new URL(r.url).pathname : '';
      throw Object.assign(new Error(path + ' answered a web page' + at), { page: true });
    }
    return r.json();
  };
  const readAll = async () => {
    const props = [];
    for (const path of ['/dashboard', '/violations', '/settings/mac', '/apply']) {
      props.push((await read(path, true)).props || {});
    }
    return [...props, await read('/wifiDevicesCount', false)];
  };
  let all;
  try {
    all = await readAll();
  } catch (e) {
    if (!e.page) throw e;
    await new Promise(done => setTimeout(done, 1500));
    all = await readAll();
  }
  const [dash, breaks, cards, apply, wifi] = all;
  Campus.postMessage(JSON.stringify({
    usage: dash.quickActions?.bandwidth_usage ?? 0,
    disabling: dash.quickActions?.disabling ?? null,
    semesters: dash.semesters ?? [],
    labels: dash.language ?? {},
    breaks: breaks.violations?.data ?? [],
    status: breaks.user_status ?? {},
    cards: cards.MACs ?? [],
    wifi: wifi.mac_count ?? 0,
    lastBed: apply.userInfo?.lastKeystone ?? null,
  }));
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';

/// Daily traffic allowance, wired cards and Wi-Fi devices at once
/// (宿網服務指南).
const dormNetDailyGiB = 100;
const dormNetCards = 3;
const dormNetWifi = 2;

typedef DormNetBreak = ({
  String kind,
  bool virus,
  DateTime? from,
  DateTime? until,
});

typedef DormNet = ({
  /// Today's traffic in GiB.
  double usage,

  /// `115 上學期`-style term, its payment state, and the bed; null term when
  /// the site lists none.
  String? term,
  String? state,
  String? bed,
  bool applied,
  String? lastBed,

  /// Why the account is cut off now, or null.
  String? suspended,
  bool canUnsuspend,
  List<DormNetBreak> breaks,
  List<String> cards,
  int wifi,
});

/// `{type, room, bed}` or a plain string, as `C312-2`.
String? _bed(Object? v) => switch (v) {
  {'room': final room, 'bed': final bed} when '$room'.isNotEmpty =>
    '$room${'$bed'.isEmpty ? '' : '-$bed'}',
  final String s when s.isNotEmpty => s,
  _ => null,
};

DormNet dormNetOf(Map<String, dynamic> json) {
  final labels = (json['labels'] as Map?) ?? const {};
  String label(String key) => '${labels[key] ?? key}';
  final first = (json['semesters'] as List? ?? const [])
      .whereType<Map>()
      .firstOrNull;
  final data = first?['data'];
  final state = data is Map ? '${data['state'] ?? ''}' : '';
  final status = (json['status'] as Map?) ?? const {};
  final disabling = json['disabling'];
  final suspended = status['suspended'] == true
      ? label('disabled.${status['reason'] ?? ''}')
      : disabling is String && disabling.isNotEmpty
      ? label('disabled.$disabling')
      : null;
  return (
    usage: (json['usage'] as num? ?? 0).toDouble(),
    term: first == null
        ? null
        : '${first['academic_year']} ${label('${first['semester']}')}',
    state: state.isEmpty ? null : label(state),
    bed: data is Map ? _bed(data['keystone']) : null,
    applied: data is Map,
    lastBed: _bed(json['lastBed']),
    suspended: suspended,
    canUnsuspend: status['can_unsuspend'] == true,
    breaks: [
      for (final b in (json['breaks'] as List? ?? const []).whereType<Map>())
        (
          kind: label('disabled.${b['type'] ?? ''}'),
          // virus, virus_aisac, virus_ewa…: each scanner has its own type.
          virus: '${b['type']}'.startsWith('virus'),
          from: DateTime.tryParse('${b['suspended_at']}'),
          until: DateTime.tryParse('${b['unsuspended_at']}'),
        ),
    ],
    cards: [
      for (final c in (json['cards'] as List? ?? const []))
        if (c is Map ? c['mac'] : c case final mac? when '$mac'.isNotEmpty)
          '$mac',
    ],
    wifi: (json['wifi'] as num? ?? 0).toInt(),
  );
}

typedef DormNetNotice = ({String title, DateTime? date, String body});

/// A public www.dorm.ccu.edu.tw API answer: a JSON list.
Future<List<Object?>> _dormApi(String path, http.Client? client) async {
  final get = client?.get ?? http.get;
  final r = await get(Uri.parse('https://www.dorm.ccu.edu.tw/api/home/$path'))
      .timeout(const Duration(seconds: 15));
  if (r.statusCode != 200) {
    throw http.ClientException('DormNet $path: ${r.statusCode}');
  }
  return jsonDecode(utf8.decode(r.bodyBytes)) as List;
}

/// The latest announcements on www.dorm.ccu.edu.tw, newest first; [english]
/// picks their English titles and texts.
Future<List<DormNetNotice>> dormNetNotices({
  int count = 5,
  bool english = false,
  http.Client? client,
}) async {
  final lang = english ? 'en' : 'zh';
  return [
    for (final a in await _dormApi('announcement?page=0&count=$count', client))
      if (a is Map)
        (
          title: '${a['title_$lang'] ?? a['title_zh'] ?? ''}',
          // "2026/7/22".
          date: switch ('${a['created_at']}'.split('/')) {
            [final y, final m, final d] => DateTime.tryParse(
              '$y-${m.padLeft(2, '0')}-${d.padLeft(2, '0')}',
            ),
            _ => null,
          },
          body: plainText('${a['content_$lang'] ?? a['content_zh'] ?? ''}'),
        ),
  ];
}

/// An office and its weekday hours as minutes into the day, null when the
/// text has none.
typedef DormNetOffice = ({
  String name,
  String? ext,
  String hours,
  int? from,
  int? to,
  bool closedFirst,
});

/// The offices on the info site's home page, written as free text: a
/// `大學部 C 棟 B1 (#73199)` heading, then the hours and any closing note.
Future<List<DormNetOffice>> dormNetOffices({
  bool english = false,
  http.Client? client,
}) async => [
  for (final o in await _dormApi('officeHour', client))
    if (o is Map)
      dormNetOfficeOf(
        plainText(
          '${o[english ? 'content_en' : 'content_zh'] ?? o['content_zh'] ?? ''}',
        ),
      ),
];

DormNetOffice dormNetOfficeOf(String text) {
  final lines = text.split('\n');
  final ext = RegExp(r'\(#(\d+)\)').firstMatch(lines.first);
  final time = RegExp(r'(\d{1,2}):(\d{2})\s*[-–~]\s*(\d{1,2}):(\d{2})')
      .firstMatch(text);
  int? at(int hour, int minute) => time == null
      ? null
      : int.parse(time[hour]!) * 60 + int.parse(time[minute]!);
  return (
    name: (ext == null ? lines.first : lines.first.replaceFirst(ext[0]!, ''))
        .trim(),
    ext: ext?[1],
    hours: lines.length > 1 ? lines[1] : '',
    from: at(1, 2),
    to: at(3, 4),
    closedFirst: text.contains('一號') || text.contains('1st'),
  );
}

/// Fee and refund by when in the term the network is applied for
/// (宿舍網路管理辦法, revised 2025-04-30); 0 is no refund.
const dormNetFees = [1000, 750, 500, 250];
const dormNetRefunds = [750, 500, 0, 0];

/// The term [d] falls in for the fee table, and which row applies: the fall
/// term runs from August (applications open late August) to January.
({bool fall, int row}) dormNetFeeRow(DateTime d) => switch (d.month) {
  8 || 9 || 10 => (fall: true, row: 0),
  11 => (fall: true, row: 1),
  12 => (fall: true, row: 2),
  1 => (fall: true, row: 3),
  2 || 3 => (fall: false, row: 0),
  4 => (fall: false, row: 1),
  5 => (fall: false, row: 2),
  _ => (fall: false, row: 3),
};

/// Whether [office] is open at [now]: its hours on weekdays, and not on the
/// 1st when its note says so.
bool dormNetOfficeOpen(DateTime now, DormNetOffice office) {
  final from = office.from, to = office.to;
  if (from == null || to == null) return false;
  final minute = now.hour * 60 + now.minute;
  return now.weekday <= DateTime.friday &&
      !(office.closedFirst && now.day == 1) &&
      minute >= from &&
      minute < to;
}

/// Days a virus disconnection lasts after reconnecting is applied for, by
/// how many there have been (宿舍網路管理辦法): 1, 1, 2, 3, then one more
/// each time, at most 14.
int dormNetPenaltyDays(int virusCount) =>
    virusCount <= 2 ? 1 : (virusCount - 1).clamp(1, 14);

/// When [office] next opens after [now], within two weeks.
DateTime? dormNetOfficeNext(DateTime now, DormNetOffice office) {
  final from = office.from;
  if (from == null) return null;
  for (var d = 0; d < 14; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    final opens = day.add(Duration(minutes: from));
    if (opens.isAfter(now) && dormNetOfficeOpen(opens, office)) return opens;
  }
  return null;
}
