import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/services/html_text.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';
import '../core/campus_systems.dart';

const _iccu = 'https://www026220.ccu.edu.tw';

/// Portal hand-off into iCCU; lands on `/home` when already signed in.
final _entry = entryUrl(campusSystems['0075']!);

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
  Campus.postMessage(JSON.stringify(out));
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
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
String _text(Object? v) => plainText('${v ?? ''}');

/// Design H2-B (design/round-11): what iCCU shows is read in-app as tall
/// bars; everything else opens the website in the shared campus WebView.
class IccuScreen extends StatefulWidget {
  const IccuScreen({super.key});

  @override
  State<IccuScreen> createState() => _IccuScreenState();
}

class _IccuScreenState extends State<IccuScreen> with CampusPageState {
  @override
  String get cacheKey => 'iccu';

  // Selections change rarely: show the last read and fetch only when
  // there is none or the user pulls to refresh.
  @override
  bool get readOnOpen => false;

  _Snapshot? get _snapshot => this.json == null ? null : _Snapshot(this.json!);

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return CampusSession(
      key: session,
      title: context.l10n.courseSelection,
      entry: _entry,
      host: Uri.parse(_iccu).host,
      loadOnStart: false,
      script: () => _script(
        [_courses, _changes, _programs, ..._applications.keys],
        [..._seasonal.keys],
      ),
      onMessage: received,
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : snapshot == null
          ? null
          : Builder(
              // Reads insets from inside the session's Scaffold.
              builder: (context) => _Hub(
                snapshot: snapshot,
                savedAt: savedAt,
                onRefresh: () async => session.currentState?.refresh(),
                openWeb: (path, title) =>
                    openCampusPage(context, '$_iccu$path', title),
              ),
            ),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({
    required this.snapshot,
    required this.savedAt,
    required this.onRefresh,
    required this.openWeb,
  });

  final _Snapshot snapshot;
  final DateTime? savedAt;
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
    final l10n = context.l10n;
    final s = snapshot;
    final courses = s.courses;
    final credits = courses.fold<num>(
      0,
      (sum, c) => sum + (num.tryParse(_text(c['Credit'])) ?? 0),
    );
    final apps = s.applications;
    return RefreshIndicator(
      // Below the glass app bar, which the body extends under.
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: onRefresh,
      child: ListView(
        padding: scrollPadding(context),
        children: [
          SectionLabel(l10n.viewInApp),
          _Bar(
            tone: t.lilac,
            value: l10n.courseCountShort(courses.length),
            title: l10n.selectionQuery,
            detail: l10n.thisSemesterCredits(_num(credits)),
            onTap: () => _push(context, l10n.selectionQuery, [
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
                  trailing: l10n.typeCredits(
                    _text(c['ChooseName']),
                    _text(c['Credit']),
                  ),
                ),
            ]),
          ),
          _Bar(
            tone: t.peach,
            value: '${s.changes.length}',
            title: l10n.courseChanges,
            detail: l10n.schoolwideChanges,
            onTap: () => _push(context, l10n.courseChanges, [
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
            title: l10n.myApplications,
            detail: apps.isEmpty
                ? l10n.applicationsHint
                : {for (final (kind, _) in apps) kind}
                      .map(
                        (k) => l10n.kindCount(
                          k,
                          apps.where((a) => a.$1 == k).length,
                        ),
                      )
                      .join('、'),
            onTap: () => _push(context, l10n.myApplications, [
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
            title: l10n.programs,
            detail: l10n.programsDetail,
            onTap: () => _push(context, l10n.programs, [
              for (final p in s.programs)
                (
                  title: _text(p['StudyCourseCategoryName']),
                  detail: _text(p['StudyCourseOfficeName']),
                  trailing: _text(p['NewYear']),
                ),
            ]),
          ),
          SectionLabel(l10n.onSchoolWebsite),
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
          if (savedAt case final time?) UpdatedAt(time),
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
        radius: Corners.row,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              // Units differ in length by language (門, 科目): shrink to
              // one line rather than wrap.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.inset),
        ),
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
                          context.l10n.notOpen,
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
            ? EmptyState(context.l10n.noData)
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
