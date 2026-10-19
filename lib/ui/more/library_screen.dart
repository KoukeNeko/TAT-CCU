import 'package:flutter/material.dart';

import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

const _host = 'ccu.primo.exlibrisgroup.com';
const _vid = '886CCU_INST:886CCU_INST';

/// What the library sign-in page's 「單一登入」 button opens: CAS, then the
/// library's IdP, which signs in to Primo over SAML. Going there directly
/// skips that page, which waits for a tap.
const _sso =
    'https://cas.ccu.edu.tw/login?service=https%3A%2F%2Fidm.lib.ccu.edu.tw%2Fsso%2Fidm%2Fcaslogin_callback%3Fnext%3D%2Fsso%2Fidm%2Fprimo%2F';
const _accountUrl = 'https://$_host/discovery/account?vid=$_vid&lang=zh-tw';
const _search = 'https://$_host/discovery/search?vid=$_vid&lang=zh-tw';

/// Primo keeps its own sign-in cookie, which outlives the CAS session, so
/// the account page is opened directly; only when Primo hands out a guest
/// JWT does the script go through CAS once. The signed-in JWT
/// sits in sessionStorage and the account API takes it as a bearer token
/// (research_notes/…/library_probe.md).
const _readAccount =
    '''
(async () => {
  const signedIn = j => { try { return JSON.parse(atob(j.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'))).signedIn === 'true'; } catch (e) { return false; } };
  const viaSso = sessionStorage.getItem('tatccuSso') === '1';
  let jwt = '';
  for (let i = 0; i < (viaSso ? 80 : 40); i++) {
    jwt = (sessionStorage.getItem('primoExploreJwt') || '').replace(/"/g, '');
    if (signedIn(jwt)) break;
    await new Promise(r => setTimeout(r, 250));
  }
  if (!signedIn(jwt)) {
    if (viaSso) throw new Error('Library sign-in did not finish');
    sessionStorage.setItem('tatccuSso', '1');
    location.href = '$_sso';
    return;
  }
  sessionStorage.removeItem('tatccuSso');
  const get = async p => {
    const r = await fetch('/primaws/rest/priv/myaccount/' + p, { headers: { Authorization: 'Bearer ' + jwt } });
    if (!r.ok) throw new Error(p.split('?')[0] + ' ' + r.status);
    return (await r.json()).data || {};
  };
  const [l, q] = await Promise.all([
    get('loans?bulk=50&lang=zh-tw&offset=1&type=active'),
    get('requests?lang=zh-tw&vid=$_vid'),
  ]);
  Campus.postMessage(JSON.stringify({ loans: l.loans?.loan ?? [], holds: q.holds?.hold ?? [] }));
})().catch(e => {
  sessionStorage.removeItem('tatccuSso');
  Campus.postMessage(JSON.stringify({ error: String(e) }));
});
''';

typedef Loan = ({String title, String author, DateTime due});
typedef Hold = ({String title, String pickup, DateTime? until});

// shortcut: field names are guessed from Primo VE (the probed account had
// no loans or holds); check them against a real loan and tighten.
String _field(Map item, List<String> names) {
  final lower = {for (final e in item.entries) '${e.key}'.toLowerCase(): e};
  for (final n in names) {
    if (lower[n]?.value case final v? when '$v'.trim().isNotEmpty) {
      return '$v'.trim();
    }
  }
  return '';
}

/// Primo dates come as `yyyyMMdd`, ISO, or `M/d/yyyy`.
DateTime? _date(String s) {
  if (RegExp(r'^\d{8}').hasMatch(s)) {
    return DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
    );
  }
  if (RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s) case final m?) {
    return DateTime(int.parse(m[3]!), int.parse(m[1]!), int.parse(m[2]!));
  }
  final t = DateTime.tryParse(s);
  return t == null ? null : DateTime(t.year, t.month, t.day);
}

/// Loans sorted most urgent first; loans without a readable due date are
/// left out rather than shown as due at a wrong time.
@visibleForTesting
List<Loan> loansOf(Map<String, dynamic> json) {
  final loans = <Loan>[
    for (final item in (json['loans'] as List? ?? const []).whereType<Map>())
      if (_date(_field(item, ['duedate', 'due_date'])) case final due?)
        (
          title: _field(item, ['title']),
          author: _field(item, ['author', 'creator']),
          due: due,
        ),
  ];
  return loans..sort((a, b) => a.due.compareTo(b.due));
}

/// Holds waiting on the pickup shelf.
@visibleForTesting
List<Hold> readyHoldsOf(Map<String, dynamic> json) => [
  for (final item in (json['holds'] as List? ?? const []).whereType<Map>())
    if (RegExp(
      r'hold ?shelf|ready|pickup|可取|待取',
      caseSensitive: false,
    ).hasMatch(_field(item, ['status', 'requeststatus', 'request_status'])))
      (
        title: _field(item, ['title']),
        pickup: _field(item, ['pickuplocation', 'pickup_location', 'pickup']),
        until: _date(
          _field(item, ['expirydate', 'holdshelfexpirydate', 'expiry_date']),
        ),
      ),
];

/// Design B1-A (design/round-11): one card with the most urgent due date
/// and holds to pick up, the loans by due date, then the library website.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _cacheKey = 'library';
  final _session = GlobalKey<CampusSessionState>();
  Map<String, dynamic>? _account;
  DateTime? _savedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Show the last read at once; due dates still count from today.
    CampusCache.read(_cacheKey).then((cached) {
      if (!mounted) return;
      if (cached == null) {
        _session.currentState?.reload();
      } else {
        setState(() {
          _account = cached.json;
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
      _account = json;
      _savedAt = savedAt;
    });
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _session.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return CampusSession(
      key: _session,
      title: context.l10n.library,
      entry: _accountUrl,
      host: _host,
      // The library's IdP posts itself on to Primo.
      via: const ['idm.lib.ccu.edu.tw'],
      loadOnStart: false,
      script: () => _readAccount,
      onMessage: _received,
      child: _error != null
          ? CampusError(message: _error!, onRetry: _reload)
          : account == null
          ? null
          : Builder(
              // Reads insets from inside the session's Scaffold.
              builder: (context) => RefreshIndicator(
                // Below the glass app bar, which the body extends under.
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: _reload,
                child: _Body(
                  loans: loansOf(account),
                  holds: readyHoldsOf(account),
                  savedAt: _savedAt,
                ),
              ),
            ),
    );
  }
}

String _md(DateTime d) => '${d.month}/${d.day}';

class _Body extends StatelessWidget {
  const _Body({required this.loans, required this.holds, this.savedAt});

  final List<Loan> loans;
  final List<Hold> holds;
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysTo(DateTime due) => due.difference(today).inDays;
    final labelStyle = Theme.of(context).textTheme.titleSmall
        ?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant);
    return ListView(
      padding: scrollPadding(context),
      children: [
        _Hero(
          loans: loans,
          holds: holds,
          daysTo: daysTo,
          tone: loans.isEmpty
              ? tones.mint
              : daysTo(loans.first.due) < 0
              ? tones.peach
              : tones.sun,
        ),
        if (loans.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
            child: Row(
              children: [
                Text(l10n.onLoan, style: labelStyle),
                const Spacer(),
                Text(l10n.bookCount(loans.length), style: labelStyle),
              ],
            ),
          ),
          for (final loan in loans)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LoanRow(loan: loan, days: daysTo(loan.due)),
            ),
        ],
        SectionLabel(l10n.onSchoolWebsite),
        Card(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (title, url) in [
                (l10n.loansAndRenewals, '$_accountUrl&section=loans'),
                (l10n.catalogSearch, _search),
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.loans,
    required this.holds,
    required this.daysTo,
    required this.tone,
  });

  final List<Loan> loans;
  final List<Hold> holds;
  final int Function(DateTime) daysTo;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const number = TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w900,
      height: 1,
    );
    const unit = TextStyle(fontSize: 16, fontWeight: FontWeight.w900);
    const note = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);
    final List<Widget> head;
    if (loans.isEmpty) {
      // The count would only repeat the sentence.
      head = [
        Text(
          l10n.noLoans,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ];
    } else {
      final first = loans.first;
      final days = daysTo(first.due);
      final sameDay = loans.where((l) => l.due == first.due).length;
      head = [
        Text(days < 0 ? l10n.loansOverdue : l10n.loansNextDue, style: note),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: '${days.abs()}',
            style: number,
            children: [TextSpan(text: ' ${l10n.unitDays}', style: unit)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.loanDue(_md(first.due))}・'
          '${sameDay == 1 ? first.title : l10n.bookCount(sameDay)}',
          style: note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ];
    }
    return ToneBlock(
      tone: tone,
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...head,
          if (holds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .1
                      : .55,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.holdsReady(holds.length),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if ([
                        holds.first.pickup,
                        if (holds.first.until case final d?)
                          l10n.heldUntil(_md(d)),
                      ].where((s) => s.isNotEmpty).join('・')
                      case final where when where.isNotEmpty)
                    Text(
                      where,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.loan, required this.days});

  final Loan loan;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final (tone, label) = days < 0
        ? (tones.peach, l10n.daysOverdue(-days))
        : days == 0
        ? (tones.sun, l10n.dueToday)
        : (days <= 3 ? tones.sun : tones.mint, l10n.loanDaysLeft(days));
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      loan.author,
                      l10n.loanDue(_md(loan.due)),
                    ].where((s) => s.isNotEmpty).join('・'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
