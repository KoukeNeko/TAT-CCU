import 'package:flutter/material.dart';

import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

const _host = 'www026186.ccu.edu.tw';
const _apply = 'https://$_host/stu_off/student/apply';
const _cancel = 'https://$_host/stu_off/student/apply/cancel';
const _entry =
    'https://portal.ccu.edu.tw/ssoService.php?service=/test_0064_StuOff.php&linkId=0064&para=';

/// The cancel page lists every request the student filed, with its status,
/// in a server-rendered `table#ApplyList-table` (申請編號｜假別｜請假日期｜
/// 假單狀態｜審核結果); a plain GET is enough
/// (research_notes/…/leave_system_probe.md).
const _readRequests = '''
(async () => {
  const h = await (await fetch('/stu_off/student/apply/cancel', { credentials: 'same-origin' })).text();
  const d = new DOMParser().parseFromString(h, 'text/html');
  const rows = [...d.querySelectorAll('#ApplyList-table tbody tr')]
    .map(tr => [...tr.cells].map(td => td.textContent.trim().replace(/\\s+/g, ' ')))
    .filter(c => c.length >= 5);
  Campus.postMessage(JSON.stringify({ rows }));
})().catch(e => Campus.postMessage(JSON.stringify({ error: String(e) })));
''';

enum _Status { approved, pending, cancelled }

typedef _Request = ({
  String number,
  String kind,
  String date,
  _Status status,
  String result,
});

/// The school words statuses freely; anything not clearly cancelled or
/// approved counts as still under review.
// shortcut: matched on wording, since no filled-in request has been seen
// yet; switch to the exact values once one is (research notes).
_Status _statusOf(String state, String result) {
  final text = '$state $result';
  if (text.contains('銷假') || text.contains('撤銷') || text.contains('取消')) {
    return _Status.cancelled;
  }
  if (text.contains('通過') || text.contains('核准') || text.contains('同意')) {
    return _Status.approved;
  }
  return _Status.pending;
}

List<_Request> _requestsOf(Map<String, dynamic> json) => [
  for (final r in (json['rows'] as List? ?? const []))
    if (r case [
      final number,
      final kind,
      final date,
      final state,
      final result,
      ...,
    ])
      (
        number: '$number',
        kind: '$kind',
        date: '$date',
        status: _statusOf('$state', '$result'),
        result: '$result',
      ),
];

/// Design L3-A (design/round-11): counts by status, the semester's requests,
/// then the school website for filing or cancelling a request.
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  static const _cacheKey = 'leave';
  final _session = GlobalKey<CampusSessionState>();
  List<_Request>? _requests;
  DateTime? _savedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Requests change rarely: show the last read and fetch only when there
    // is none or the user pulls to refresh.
    CampusCache.read(_cacheKey).then((cached) {
      if (!mounted) return;
      if (cached == null) {
        _session.currentState?.reload();
      } else {
        setState(() {
          _requests = _requestsOf(cached.json);
          _savedAt = cached.savedAt;
        });
      }
    });
  }

  Future<void> _received(Map<String, dynamic> json) async {
    if (json['error'] != null) {
      setState(() => _error = '${json['error']}');
      return;
    }
    final savedAt = await CampusCache.write(_cacheKey, json);
    if (!mounted) return;
    setState(() {
      _error = null;
      _requests = _requestsOf(json);
      _savedAt = savedAt;
    });
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _session.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final requests = _requests;
    return CampusSession(
      key: _session,
      title: context.l10n.leave,
      entry: _entry,
      host: _host,
      loadOnStart: false,
      script: () => _readRequests,
      onMessage: _received,
      child: _error != null
          ? CampusError(message: _error!, onRetry: _reload)
          : requests == null
          ? null
          : Builder(
              // Reads insets from inside the session's Scaffold.
              builder: (context) => RefreshIndicator(
                // Below the glass app bar, which the body extends under.
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: () async => _session.currentState?.refresh(),
                child: _Body(requests: requests, savedAt: _savedAt),
              ),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.requests, required this.savedAt});

  final List<_Request> requests;
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final neutral = Tone(
      scheme.surfaceContainerHigh,
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );
    int count(_Status s) => requests.where((r) => r.status == s).length;
    return ListView(
      padding: scrollPadding(context),
      children: [
        Row(
          children: [
            for (final (i, (tone, status, label)) in [
              (tones.mint, _Status.approved, l10n.leaveApproved),
              (tones.sun, _Status.pending, l10n.leavePending),
              (neutral, _Status.cancelled, l10n.leaveCancelled),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: ToneBlock(
                  tone: tone,
                  radius: Corners.row,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${count(status)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        SectionLabel(
          l10n.myLeaves,
          detail: requests.isEmpty ? null : l10n.recordCount(requests.length),
        ),
        if (requests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              l10n.noLeaves,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        for (final r in requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RequestRow(request: r, neutral: neutral),
          ),
        SectionLabel(l10n.onSchoolWebsite),
        Card(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (title, url) in [
                (l10n.applyLeave, _apply),
                (l10n.cancelLeave, _cancel),
              ])
                ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: Icon(
                    Icons.north_east,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () => openCampusPage(context, url, title),
                ),
            ],
          ),
        ),
        if (savedAt case final time?) UpdatedAt(time),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.neutral});

  final _Request request;
  final Tone neutral;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final (tone, label) = switch (request.status) {
      _Status.approved => (tones.mint, l10n.leaveApproved),
      _Status.pending => (tones.sun, l10n.leavePending),
      _Status.cancelled => (neutral, l10n.leaveCancelled),
    };
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.row),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.kind,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.date}・${request.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: ShapeDecoration(
                color: tone.fill,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    color: tone.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
