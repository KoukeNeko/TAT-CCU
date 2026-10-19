/// The library's event sign-up system (events.lib.ccu.edu.tw): a Django site
/// rendered on the server. Public pages are fetched here; what needs the
/// student (我的活動, signing up, cancelling) runs same-origin in the
/// signed-in WebView. Both produce the JSON [eventOf] reads
/// (research_notes/…/activity_signup_probe.md).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'html_text.dart';

const eventsHost = 'events.lib.ccu.edu.tw';
const eventsOrigin = 'https://$eventsHost';

/// Signs in through CAS and lands on [next].
String eventsEntry([String next = '/']) =>
    '$eventsOrigin/sso/login/?next=${Uri.encodeQueryComponent(next)}';

enum EventStatus {
  /// Signing up in the app.
  open,

  /// Every place taken; signing up joins the waitlist.
  waitlist,

  /// Places and waitlist both taken.
  full,

  /// Signed up already.
  mine,

  /// Signing up happens elsewhere (a form linked in the description).
  external,

  /// The sign-up period is over.
  closed,
}

typedef SchoolEvent = ({
  String id,
  String title,
  String? image,
  DateTime? start,
  DateTime? end,
  String place,
  String category,
  String organizer,
  String contact,
  String intro,
  String? link,
  DateTime? signUpEnd,
  ({int taken, int total})? spots,
  ({int taken, int total})? waitlist,
  bool canSignUp,
  bool signedUp,
  String? cancel,
});

SchoolEvent eventOf(Map<String, dynamic> j) {
  ({int taken, int total})? pair(Object? v) => v is List && v.length == 2
      ? (taken: v[0] as int, total: v[1] as int)
      : null;
  DateTime? date(Object? v) => v == null ? null : DateTime.tryParse('$v');
  return (
    id: '${j['id']}',
    title: '${j['title']}',
    image: j['image'] == null ? null : '$eventsOrigin${j['image']}',
    start: date(j['start']),
    end: date(j['end']),
    place: '${j['place'] ?? ''}',
    category: '${j['category'] ?? ''}',
    organizer: '${j['org'] ?? ''}',
    contact: [
      j['contact'],
      j['phone'],
      j['email'],
    ].whereType<String>().where((s) => s.isNotEmpty).join('・'),
    intro: '${j['intro'] ?? ''}',
    link: j['link'] as String?,
    signUpEnd: date(j['signUpEnd']),
    spots: pair(j['spots']),
    waitlist: pair(j['waitlist']),
    canSignUp: j['canSignUp'] == true,
    signedUp: j['signedUp'] == true,
    cancel: j['cancel'] as String?,
  );
}

/// Read from what the page shows: the site hides the sign-up button both
/// when the period is over and when every place, waitlist included, is
/// taken.
EventStatus statusOf(SchoolEvent e, DateTime now) {
  if (e.signedUp) return EventStatus.mine;
  if (e.canSignUp) {
    final s = e.spots;
    return s != null && s.taken >= s.total
        ? EventStatus.waitlist
        : EventStatus.open;
  }
  if (e.signUpEnd case final end? when end.isBefore(now)) {
    return EventStatus.closed;
  }
  if (e.spots != null) return EventStatus.full;
  return e.link != null ? EventStatus.external : EventStatus.closed;
}

/// Reads one detail page; shared by the list and detail scripts.
const _parseEvent = r'''
const text = s => (s || '').replace(/\s+/g, ' ').trim();
const nums = s => (s.match(/\d+/g) || []).map(Number);
const iso = (d, t) => d.replace(/\//g, '-') + 'T' + t + ':00';
const page = async u => {
  const r = await fetch(u, { credentials: 'same-origin' });
  if (!r.ok) throw new Error(u + ' ' + r.status);
  return r.text();
};
const parseEvent = (id, h) => {
  const d = new DOMParser().parseFromString(h, 'text/html');
  const box = d.querySelector('.uk-panel-box') || d.body;
  const dd = {};
  d.querySelectorAll('dt').forEach(dt => { if (dt.nextElementSibling) dd[text(dt.textContent)] = dt.nextElementSibling; });
  const h4 = [...box.querySelectorAll('h4')].map(e => text(e.textContent));
  const quota = h4.find(s => s.startsWith('報名名額'));
  const period = h4.find(s => s.startsWith('報名起訖'));
  const q = quota ? nums(quota) : [];
  const img = (box.querySelector('[style*="event_picture"]')?.getAttribute('style') || '').match(/url\('?([^')]+)/);
  const when = text(dd['活動日期']?.textContent).match(/(\d{4}\/\d\d\/\d\d)\D*?(\d\d:\d\d)\s*~\s*(\d{4}\/\d\d\/\d\d)\D*?(\d\d:\d\d)/);
  const until = period && period.match(/~\s*(\d{4}\/\d\d\/\d\d)\s+(\d\d:\d\d)/);
  const intro = dd['活動介紹'];
  let about = '';
  if (intro) {
    const c = intro.cloneNode(true);
    c.querySelectorAll('br').forEach(b => b.replaceWith('\n'));
    c.querySelectorAll('p, div, li').forEach(p => p.append('\n'));
    about = c.textContent.split('\n').map(s => s.replace(/[ \t\u00a0]+/g, ' ').trim()).filter(Boolean).join('\n');
  }
  const link = [...(intro ? intro.querySelectorAll('a[href^="http"]') : [])]
    .map(a => a.href).find(u => !/facebook|instagram|youtube/.test(u)) || null;
  const signedUp = [...box.querySelectorAll('button')].some(b => text(b.textContent) === '我要取消');
  const cancel = signedUp ? ((h.match(/\/event\/canceledjoin\/[0-9a-f]+\/(?:list\/)?/) || [])[0] || null) : null;
  return {
    id, title: text(box.querySelector('h3')?.textContent),
    image: img ? img[1] : null,
    start: when ? iso(when[1], when[2]) : null, end: when ? iso(when[3], when[4]) : null,
    place: text(dd['地點']?.textContent),
    category: text(dd['活動類別']?.textContent).replace(/\s+[A-Za-z].*$/, ''),
    org: text(dd['承辦單位']?.textContent), contact: text(dd['聯絡人']?.textContent),
    phone: text(dd['聯絡電話']?.textContent), email: text(dd['Email']?.textContent),
    intro: about, link, signUpEnd: until ? iso(until[1], until[2]) : null,
    spots: q.length >= 2 ? [q[0], q[1]] : null, waitlist: q.length >= 4 ? [q[2], q[3]] : null,
    canSignUp: !!box.querySelector('a[href^="/event/add/"]'), signedUp, cancel,
  };
};
const post = o => Campus.postMessage(JSON.stringify(o));
''';

/// The student's sign-ups and counts from 我的活動, which needs signing in.
const readMine =
    '''
(async () => {
$_parseEvent
  const m = new DOMParser().parseFromString(await page('/my/'), 'text/html');
  const panes = [...m.querySelectorAll('.uk-switcher > li')];
  const rows = pane => [...(pane ? pane.querySelectorAll('a[href*="/event/detail/"]') : [])]
    .map(a => ({ id: (a.getAttribute('href').match(/(\\d+)\\/?\$/) || [])[1], title: text(a.getAttribute('title') || a.textContent) }))
    .filter(r => r.id);
  const stat = re => (m.body.textContent.match(re) || [])[1] || '0';
  post({
    mine: rows(panes[0]), past: rows(panes[1]),
    attended: Number(stat(/參與的活動總場次\\s*(\\d+)/)), hours: stat(/參與的活動總時數\\s*([\\d.]+)/),
  });
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';

// The list, categories, search and details are public pages, read natively:
// dozens of them at once would crawl in a hidden WebView, which iOS
// throttles.

final _ids = RegExp(r'/event/detail/list/(\d+)/');

Future<String> _page(http.Client client, String path) async {
  final res = await client
      .get(Uri.parse('$eventsOrigin$path'))
      .timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw Exception('$path ${res.statusCode}');
  return utf8.decode(res.bodyBytes);
}

List<String> _idsIn(String html) =>
    {for (final m in _ids.allMatches(html)) m[1]!}.toList();

String _line(String html) => plainText(html).replaceAll('\n', ' ');

/// One detail page as the JSON [eventOf] reads; the same fields the
/// signed-in script returns, without the student's own state.
Map<String, dynamic> parseEventPage(String id, String html) {
  final at = html.indexOf('uk-panel-box');
  final box = at < 0 ? html : html.substring(at);
  final dd = {
    for (final m in RegExp(
      r'<dt[^>]*>([\s\S]*?)</dt>\s*<dd[^>]*>([\s\S]*?)</dd>',
    ).allMatches(box))
      _line(m[1]!): m[2]!,
  };
  final h4 = [
    for (final m in RegExp(r'<h4[^>]*>([\s\S]*?)</h4>').allMatches(box))
      _line(m[1]!),
  ];
  List<int> nums(String s) => [
    for (final m in RegExp(r'\d+').allMatches(s)) int.parse(m[0]!),
  ];
  final quota = h4.where((s) => s.startsWith('報名名額')).firstOrNull;
  final period = h4.where((s) => s.startsWith('報名起訖')).firstOrNull;
  final q = quota == null ? const <int>[] : nums(quota);
  String iso(String d, String t) => '${d.replaceAll('/', '-')}T$t:00';
  final when = RegExp(
    r'(\d{4}/\d\d/\d\d)\D*?(\d\d:\d\d)\s*~\s*(\d{4}/\d\d/\d\d)\D*?(\d\d:\d\d)',
  ).firstMatch(_line(dd['活動日期'] ?? ''));
  final until = period == null
      ? null
      : RegExp(r'~\s*(\d{4}/\d\d/\d\d)\s+(\d\d:\d\d)').firstMatch(period);
  final intro = dd['活動介紹'] ?? '';
  final link = RegExp(r'''href=["'](https?://[^"']+)''')
      .allMatches(intro)
      .map((m) => plainText(m[1]!))
      .where((u) => !RegExp('facebook|instagram|youtube').hasMatch(u))
      .firstOrNull;
  return {
    'id': id,
    'title': _line(
      RegExp(r'<h3[^>]*>([\s\S]*?)</h3>').firstMatch(box)?[1] ?? '',
    ),
    'image': RegExp(r"url\('?(/media/event_picture/[^')]+)")
        .firstMatch(box)?[1],
    'start': when == null ? null : iso(when[1]!, when[2]!),
    'end': when == null ? null : iso(when[3]!, when[4]!),
    'place': _line(dd['地點'] ?? ''),
    'category': _line(dd['活動類別'] ?? '')
        .replaceFirst(RegExp(r'\s+[A-Za-z].*$'), ''),
    'org': _line(dd['承辦單位'] ?? ''),
    'contact': _line(dd['聯絡人'] ?? ''),
    'phone': _line(dd['聯絡電話'] ?? ''),
    'email': _line(dd['Email'] ?? ''),
    'intro': plainText(intro),
    'link': link,
    'signUpEnd': until == null ? null : iso(until[1]!, until[2]!),
    'spots': q.length >= 2 ? [q[0], q[1]] : null,
    'waitlist': q.length >= 4 ? [q[2], q[3]] : null,
    'canSignUp': box.contains('href="/event/add/'),
  };
}

Future<List<Map<String, dynamic>>> _details(
  http.Client client,
  List<String> ids,
) => Future.wait([
  for (final id in ids)
    _page(client, '/event/detail/list/$id/').then((h) => parseEventPage(id, h)),
]);

/// Every current event with its details, and each site category with the
/// ids it lists.
Future<Map<String, dynamic>> fetchEvents(http.Client client) async {
  final all = await _page(client, '/event/search/');
  final tabs = <String, String>{};
  for (final m in RegExp(
    r'href="/event/search/\?tab=(\d+)"[^>]*>([\s\S]*?)</a>',
  ).allMatches(all)) {
    final name = _line(m[2]!).replaceFirst(RegExp(r'\s*[A-Za-z(（].*$'), '');
    if (name.isNotEmpty && !tabs.containsValue(name)) tabs[m[1]!] = name;
  }
  final (events, lists) = await (
    _details(client, _idsIn(all)),
    Future.wait([
      for (final MapEntry(key: tab, value: name) in tabs.entries)
        _page(
          client,
          '/event/search/?tab=$tab',
        ).then((h) => MapEntry(name, _idsIn(h))),
    ]),
  ).wait;
  return {'events': events, 'categories': Map.fromEntries(lists)};
}

/// The site's own keyword search, which also matches descriptions.
Future<List<Map<String, dynamic>>> searchEvents(
  http.Client client,
  String query,
) async => _details(
  client,
  _idsIn(
    await _page(
      client,
      '/event/search/?keywords=${Uri.encodeQueryComponent(query)}',
    ),
  ),
);

/// One event, after an optional sign-up or cancel; with the sign-up form's
/// name and email when it can be signed up for. A sign-up is a POST of the
/// form with its CSRF token; cancelling is a plain GET of the link the
/// page's cancel dialog goes to.
String readEvent(String id, Map<String, String>? action) =>
    '''
(async () => {
$_parseEvent
  const id = ${jsonEncode(id)};
  const action = ${jsonEncode(action ?? const {})};
  const alertOf = t => (t.match(/alert\\(['"]([^'"]+)['"]\\)/) || [])[1] || '';
  let result = null;
  if (action.signUp !== undefined) {
    const f = new DOMParser().parseFromString(await page('/event/add/' + id + '/'), 'text/html');
    const body = new URLSearchParams({
      csrfmiddlewaretoken: f.querySelector('[name=csrfmiddlewaretoken]')?.value || '',
      email: action.signUp,
    });
    const r = await fetch('/event/add/' + id + '/', { method: 'POST', body, credentials: 'same-origin' });
    result = { kind: 'signUp', message: alertOf(await r.text()) };
  } else if (action.cancel) {
    const r = await fetch(action.cancel, { credentials: 'same-origin' });
    result = { kind: 'cancel', message: alertOf(await r.text()) };
  }
  const event = parseEvent(id, await page('/event/detail/list/' + id + '/'));
  let form = null;
  if (event.canSignUp) {
    const r = await fetch('/event/add/' + id + '/', { credentials: 'same-origin' });
    if (r.ok) {
      const f = new DOMParser().parseFromString(await r.text(), 'text/html');
      const label = [...f.querySelectorAll('label, dt, h4, h5, b, strong, p, div')]
        .find(e => e.children.length === 0 && text(e.textContent) === '報名者姓名');
      form = {
        name: label ? text(label.nextElementSibling?.textContent || '') : '',
        email: f.querySelector('[name=email]')?.value || '',
      };
    }
  }
  post({ event, form, result });
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';
