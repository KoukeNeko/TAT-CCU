import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

const _iccu = 'https://www026220.ccu.edu.tw';

/// Portal hand-off into iCCU; lands on `/home` when already signed in.
const _entry =
    'https://portal.ccu.edu.tw/ssoService.php?service=/test_0075_nidalap_CourseSelection.php&linkId=0075&para=';

typedef _Rows = List<Map<String, dynamic>>;

/// Pages read in-app. iCCU embeds each table's rows as DataTables JSON
/// (`"data":[{…}]`) in the page, so a plain GET is enough
/// (research_notes/…/iccu_timetable_probe.md).
const _courses = '/b04/b04250';
const _changes = '/b03/b03280';
const _programs = '/b09/b09130';
const _applications = {
  '/b04/b04266': '加簽',
  '/b04/b04141': '超短修',
  '/b05/b05280': '校際選課',
  '/b06/b06112': '棄選',
  '/b08/b08201': '學分學程',
  '/b08/b08206': '客製化學程',
  '/b08/b08210': '學程證書',
};

/// Selection pages that redirect away outside the selection period.
const _seasonal = {
  '/b04/b04241': '登記選課',
  '/b04/b04210': '志願選課',
  '/b04/b04245': '退選',
  '/b04/b04321': '所際選課',
};

/// Done on the website only.
const _webOnly = {
  '/b04/b04266': '申請加簽',
  '/b04/b04141': '申請超短修',
  '/b05/b05280': '校際選課',
  '/b06/b06112': '學生棄選',
  '/b08/b08201': '學分學程',
  '/b04/b04209': '畢業審查',
  '/b09/b09120': '開課資料查詢',
  '/b09/b09125': '進階開課查詢',
};

/// Runs inside an iCCU page: fetches each path same-origin and posts back
/// the embedded `"data":[…]` arrays, or for seasonal pages whether they are
/// open. Only GETs; nothing is submitted.
String _script(List<String> data, List<String> seasonal) =>
    '''
(async () => {
  function arrays(h) {
    const res = []; let k = 0;
    while ((k = h.indexOf('"data":[', k)) >= 0) {
      let s = k + 7, depth = 0, j = s;
      for (; j < h.length; j++) {
        const c = h[j];
        if (c === '"') { j++; while (j < h.length && h[j] !== '"') { if (h[j] === '\\\\') j++; j++; } continue; }
        if (c === '[' || c === '{') depth++;
        else if (c === ']' || c === '}') { depth--; if (depth === 0) break; }
      }
      try { res.push(JSON.parse(h.slice(s, j + 1))); } catch (e) {}
      k = j;
    }
    return res;
  }
  const out = { data: {}, open: {} };
  for (const p of ${jsonEncode(data)}) {
    out.data[p] = arrays(await (await fetch(p, { credentials: 'same-origin' })).text());
  }
  for (const p of ${jsonEncode(seasonal)}) {
    const r = await fetch(p, { credentials: 'same-origin', redirect: 'manual' });
    out.open[p] = r.type !== 'opaqueredirect' && r.ok;
  }
  IccuData.postMessage(JSON.stringify(out));
})().catch(e => IccuData.postMessage(JSON.stringify({ error: String(e) })));
''';

/// What the hub shows, taken from the arrays the script returns.
class _Snapshot {
  _Snapshot(Map<String, dynamic> json)
    : _data = (json['data'] as Map).cast<String, dynamic>(),
      open = (json['open'] as Map).cast<String, dynamic>().map(
        (k, v) => MapEntry(k, v == true),
      );

  final Map<String, dynamic> _data;
  final Map<String, bool> open;

  /// The first embedded array on [path] whose rows carry [field].
  _Rows rows(String path, String field) {
    for (final a in (_data[path] as List? ?? const [])) {
      final list = (a as List).whereType<Map>().toList();
      if (list.isNotEmpty && list.first.containsKey(field)) {
        return [for (final m in list) m.cast<String, dynamic>()];
      }
    }
    return const [];
  }

  _Rows get courses => rows(_courses, 'SemesterCourseName');
  _Rows get changes => rows(_changes, 'ChangeTypeName');
  _Rows get programs => rows(_programs, 'StudyCourseCategoryName');

  List<(String, Map<String, dynamic>)> get applications => [
    for (final MapEntry(key: path, value: kind) in _applications.entries)
      for (final r in rows(path, 'ACADYear')) (kind, r),
  ];
}

/// iCCU values are plain text with the odd tag or entity.
String _text(Object? v) => '${v ?? ''}'
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .trim();

enum _Phase { loading, signIn, ready }

/// Design H2-B (design/round-11): what iCCU shows is read in-app as tall
/// bars; everything else opens the website in the shared campus WebView.
class IccuScreen extends StatefulWidget {
  const IccuScreen({super.key});

  @override
  State<IccuScreen> createState() => _IccuScreenState();
}

class _IccuScreenState extends State<IccuScreen> {
  late final WebViewController _web;
  var _phase = _Phase.loading;
  _Snapshot? _snapshot;
  String? _error;
  var _fetching = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('IccuData', onMessageReceived: _received)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _arrived));
    _load();
  }

  void _load() {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
      _fetching = false;
    });
    _web.loadRequest(Uri.parse(_entry));
  }

  void _arrived(String url) {
    final uri = Uri.parse(url);
    if (uri.host == Uri.parse(_iccu).host) {
      if (_fetching) return;
      _fetching = true;
      setState(() => _phase = _Phase.loading);
      _web.runJavaScript(
        _script(
          [_courses, _changes, _programs, ..._applications.keys],
          [..._seasonal.keys],
        ),
      );
    } else if (uri.host == 'portal.ccu.edu.tw' &&
        uri.path == '/sso_index.php') {
      // Signing in ends on the portal home, not the system it came from.
      _web.loadRequest(Uri.parse(_entry));
    } else {
      // Portal or CAS sign-in form: the user has to fill it in (Turnstile).
      setState(() => _phase = _Phase.signIn);
    }
  }

  void _received(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    setState(() {
      if (json['error'] != null) {
        _error = '${json['error']}';
      } else {
        _snapshot = _Snapshot(json);
      }
      _phase = _Phase.ready;
    });
  }

  void _openWeb(String path, String title) =>
      openCampusPage(context, '$_iccu$path', title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _phase != _Phase.signIn,
      appBar: subBar(context, _phase == _Phase.signIn ? '登入單一入口' : '選課系統'),
      body: Stack(
        children: [
          // Kept in the tree so it can load; shown only for signing in.
          Positioned.fill(
            child: Offstage(
              offstage: _phase != _Phase.signIn,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: WebViewWidget(controller: _web),
              ),
            ),
          ),
          if (_phase == _Phase.loading)
            const Center(child: CircularProgressIndicator()),
          if (_phase == _Phase.ready)
            Positioned.fill(
              child: Builder(
                builder: (context) => _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('重試'),
                            ),
                          ],
                        ),
                      )
                    : _Hub(
                        snapshot: _snapshot!,
                        onRefresh: () async => _load(),
                        openWeb: _openWeb,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({
    required this.snapshot,
    required this.onRefresh,
    required this.openWeb,
  });

  final _Snapshot snapshot;
  final Future<void> Function() onRefresh;
  final void Function(String path, String title) openWeb;

  void _push(BuildContext context, String title, List<_Row> rows) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _RecordsScreen(title: title, rows: rows),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final s = snapshot;
    final courses = s.courses;
    final credits = courses.fold<num>(
      0,
      (sum, c) => sum + (num.tryParse(_text(c['Credit'])) ?? 0),
    );
    final apps = s.applications;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: scrollPadding(context),
        children: [
          const SectionLabel('在 App 查看'),
          _Bar(
            tone: t.lilac,
            value: '${courses.length} 門',
            title: '選課查詢',
            detail: '本學期・${_num(credits)} 學分',
            onTap: () => _push(context, '選課查詢', [
              for (final c in courses)
                (
                  title: _text(c['SemesterCourseName']),
                  detail: [
                    _text(c['SemCourseTime']),
                    _text(c['ClassRoom']),
                    _text(c['Teacher']),
                    if (_text(c['IsStopName']) != '正常開課')
                      _text(c['IsStopName']),
                  ].where((v) => v.isNotEmpty).join('・'),
                  trailing:
                      '${_text(c['ChooseName'])} ${_text(c['Credit'])} 學分',
                ),
            ]),
          ),
          _Bar(
            tone: t.peach,
            value: '${s.changes.length}',
            title: '開排課異動查詢',
            detail: '全校本學期異動',
            onTap: () => _push(context, '開排課異動', [
              for (final c in s.changes)
                (
                  title: _text(c['SemesterCourseName']),
                  detail:
                      '${_text(c['OriginalTime'])} ${_text(c['OriginalClassRoom'])}'
                      ' → ${_text(c['CurrentTime'])} ${_text(c['CurrentClassRoom'])}',
                  trailing: _text(c['ChangeTypeName']),
                ),
            ]),
          ),
          _Bar(
            tone: t.mint,
            value: '${apps.length}',
            title: '我的申請',
            detail: apps.isEmpty
                ? '加簽、超短修、校際、棄選、學程'
                : {for (final (kind, _) in apps) kind}
                      .map((k) => '$k ${apps.where((a) => a.$1 == k).length} 筆')
                      .join('、'),
            onTap: () => _push(context, '我的申請', [
              for (final (kind, r) in apps)
                (
                  title: _text(r['SemesterCourseName'] ?? kind),
                  detail: [
                    kind,
                    _text(r['ACADYear']),
                    _text(r['SemesterName']),
                  ].where((v) => v.isNotEmpty).join('・'),
                  trailing: _text(r['SignState']),
                ),
            ]),
          ),
          _Bar(
            tone: t.identity[2],
            value: '${s.programs.length}',
            title: '跨領域學程',
            detail: '學程與開設單位',
            onTap: () => _push(context, '跨領域學程', [
              for (final p in s.programs)
                (
                  title: _text(p['StudyCourseCategoryName']),
                  detail: _text(p['StudyCourseOfficeName']),
                  trailing: _text(p['NewYear']),
                ),
            ]),
          ),
          const SectionLabel('在學校網站辦理'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            // A nested GridView otherwise pads itself by the screen insets.
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: [
              for (final MapEntry(key: path, value: name) in _seasonal.entries)
                _WebTile(
                  title: name,
                  closed: !(s.open[path] ?? false),
                  onTap: () => openWeb(path, name),
                ),
              for (final MapEntry(key: path, value: name) in _webOnly.entries)
                _WebTile(title: name, onTap: () => openWeb(path, name)),
            ],
          ),
        ],
      ),
    );
  }
}

String _num(num n) => n % 1 == 0 ? '${n.toInt()}' : '$n';

class _Bar extends StatelessWidget {
  const _Bar({
    required this.tone,
    required this.value,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final Tone tone;
  final String value, title, detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ToneBlock(
        tone: tone,
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _WebTile extends StatelessWidget {
  const _WebTile({
    required this.title,
    required this.onTap,
    this.closed = false,
  });

  final String title;
  final bool closed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: closed ? 0.55 : 1,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (closed)
                        Text(
                          '未開放',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.north_east,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Row = ({String title, String detail, String trailing});

class _RecordsScreen extends StatelessWidget {
  const _RecordsScreen({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, title),
      body: Builder(
        builder: (context) => rows.isEmpty
            ? const EmptyState('沒有資料')
            : ListView(
                padding: scrollPadding(context),
                children: [
                  Card(
                    color: scheme.surfaceContainerLow,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, r) in rows.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, color: scheme.outlineVariant),
                          ListTile(
                            title: Text(
                              r.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: r.detail.isEmpty ? null : Text(r.detail),
                            trailing: r.trailing.isEmpty
                                ? null
                                : Text(
                                    r.trailing,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
