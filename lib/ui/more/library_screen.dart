import 'dart:convert';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';

import '../../data/services/demo_data.dart';
import '../../data/repositories/campus_cache.dart';
import '../../data/services/library_data.dart';
import '../../l10n/l10n.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/glass_sheet.dart';
import '../core/widgets.dart';

const _host = 'ccu.primo.exlibrisgroup.com';
const _vid = '886CCU_INST:886CCU_INST';

/// What the library sign-in page's 「單一登入」 button opens: CAS, then the
/// library's IdP, which signs in to Primo over SAML. Going there directly
/// skips that page, which waits for a tap.
const _sso =
    'https://cas.ccu.edu.tw/login?service=https%3A%2F%2Fidm.lib.ccu.edu.tw%2Fsso%2Fidm%2Fcaslogin_callback%3Fnext%3D%2Fsso%2Fidm%2Fprimo%2F';
const _accountUrl = 'https://$_host/discovery/account?vid=$_vid&lang=zh-tw';

/// Primo keeps its own sign-in cookie, which outlives the CAS session, so
/// the account page is opened directly; only when Primo hands out a guest
/// JWT does the script go through CAS once. The signed-in JWT
/// sits in sessionStorage and the account API takes it as a bearer token
/// (research_notes/…/library_probe.md).
String _readAccount(Map<String, String>? action) =>
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
  const headers = { Authorization: 'Bearer ' + jwt, 'Content-Type': 'application/json' };
  const get = async p => {
    const r = await fetch('/primaws/rest/priv/myaccount/' + p, { headers });
    if (!r.ok) throw new Error(p.split('?')[0] + ' ' + r.status);
    return (await r.json()).data || {};
  };
  // Write calls as Primo's own account pages make them (library_probe.md).
  const post = async (p, body) => {
    const r = await fetch('/primaws/rest/priv/myaccount/' + p + '?lang=zh-tw', { method: 'POST', headers, body: JSON.stringify(body) });
    const j = await r.json().catch(() => ({}));
    return { ok: r.ok && j.status !== 'error', j };
  };
  const action = ${jsonEncode(action)};
  let result = null;
  if (action?.renew) {
    const { ok, j } = await post('renew_loans', { id: action.renew });
    const loan = j.data?.loans?.loan?.[0] || {};
    result = { kind: 'renew', renewed: ok ? (loan.renewed || 'N') : 'N', message: loan.lastrenewstatus || loan.renewstatus || loan.statusmessage || j['reply-text'] || '' };
  } else if (action?.renewAll) {
    const { ok, j } = await post('renew_all_loans', { lang: 'zh-tw' });
    const loans = j.data?.loans?.loan || [];
    result = { kind: 'renewAll', ok, renewed: loans.filter(x => x.renewed === 'Y').length, total: loans.length };
  } else if (action?.cancel) {
    const { ok, j } = await post('cancel_requests', { request_id: action.cancel, request_type: action.type });
    result = { kind: 'cancel', ok, message: j['reply-text'] || '' };
  }
  const [l, q] = await Promise.all([
    get('loans?bulk=50&lang=zh-tw&offset=1&type=active'),
    get('requests?lang=zh-tw&vid=$_vid'),
  ]);
  Campus.postMessage(JSON.stringify({ loans: l.loans?.loan ?? [], holds: q.holds?.hold ?? [], result }));
})().catch(e => {
  sessionStorage.removeItem('tatccuSso');
  Campus.postMessage(JSON.stringify({ error: String(e) }));
});
''';

/// The most urgent loan as a status line, from the page's saved data; null
/// when nothing is on loan or the page has not been opened yet.
({String text, bool overdue})? loanStatus(
  AppLocalizations l10n,
  CachedPage? cached,
) {
  final loan = cached == null ? null : loansOf(cached.json).firstOrNull;
  if (loan == null) return null;
  final now = clk.clock.now();
  final days = loan.due
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  return (
    text: days < 0
        ? l10n.daysOverdue(-days)
        : days == 0
        ? l10n.dueToday
        : l10n.loanDaysLeft(days),
    overdue: days < 0,
  );
}

/// Design B1-A (design/round-11): one card with the most urgent due date
/// and holds to pick up, the loans by due date, then the library website.
class LibraryScreen extends StatefulWidget {
  static const cacheKey = 'library';

  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutoRefresh, CampusPageState {
  @override
  String get cacheKey => LibraryScreen.cacheKey;

  // Show the last read at once; due dates still count from today.
  @override
  bool get readOnOpen => false;

  Map<String, dynamic>? get _account => this.json;

  /// Sent with the next read: renew a loan, renew all, or cancel a hold.
  Map<String, String>? _action;

  /// A renew or cancel reports its result beside the account, which is
  /// saved without it.
  @override
  Future<void> received(Map<String, dynamic> message) async {
    final result = message.remove('result');
    if (message['error'] == null) _action = null;
    await super.received(message);
    if (mounted && result is Map) _report(result);
  }

  /// Success shows in the list itself (a later due date, a hold gone);
  /// only what the list cannot say gets a snack bar.
  void _report(Map result) {
    final l10n = context.l10n;
    final message = switch (result['kind']) {
      'renew' when result['renewed'] == 'Y' => null,
      'renew' when result['renewed'] == 'P' => l10n.renewPending,
      'renew' => [
        l10n.renewFailed,
        '${result['message'] ?? ''}'.trim(),
      ].where((s) => s.isNotEmpty).join('：'),
      'renewAll' when result['ok'] == true => l10n.renewedCount(
        (result['renewed'] as num?)?.toInt() ?? 0,
        (result['total'] as num?)?.toInt() ?? 0,
      ),
      'renewAll' => l10n.renewFailed,
      'cancel' when result['ok'] == true => null,
      _ => l10n.cancelHoldFailed,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _act(Map<String, String> action) {
    _action = action;
    session.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return CampusSession(
      key: session,
      title: context.l10n.library,
      entry: _accountUrl,
      host: _host,
      // The library's IdP posts itself on to Primo, except its sign-in
      // page, which waits for 「單一登入」.
      casLinks: const ['idm.lib.ccu.edu.tw/sso/idm/saml2/login'],
      via: const ['idm.lib.ccu.edu.tw'],
      loadOnStart: false,
      script: () => _readAccount(_action),
      demo: DemoCampus.library,
      onMessage: received,
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : account == null
          ? null
          : Builder(
              // Reads insets from inside the session's Scaffold.
              builder: (context) => PullRefresh(
                onRefresh: () async => session.currentState?.refresh(),
                child: _Body(
                  loans: loansOf(account),
                  holds: holdsOf(account),
                  savedAt: savedAt,
                  onRenew: (loan) => _act({'renew': loan.id}),
                  onRenewAll: () => _act({'renewAll': '1'}),
                  onCancel: (hold) =>
                      _act({'cancel': hold.id, 'type': hold.type}),
                ),
              ),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.loans,
    required this.holds,
    required this.onRenew,
    required this.onRenewAll,
    required this.onCancel,
    this.savedAt,
  });

  final List<Loan> loans;
  final List<Hold> holds;
  final DateTime? savedAt;
  final ValueChanged<Loan> onRenew;
  final VoidCallback onRenewAll;
  final ValueChanged<Hold> onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final now = clk.clock.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysTo(DateTime due) => due.difference(today).inDays;
    return ListView(
      padding: scrollPadding(context),
      children: [
        _Hero(
          loans: loans,
          holds: [
            for (final h in holds)
              if (h.ready) h,
          ],
          daysTo: daysTo,
          tone: loans.isEmpty
              ? tones.mint
              : daysTo(loans.first.due) < 0
              ? tones.peach
              : tones.sun,
        ),
        if (loans.isNotEmpty) ...[
          SectionLabel(
            '${l10n.onLoan}・${l10n.bookCount(loans.length)}',
            action: TextButton(
              onPressed: onRenewAll,
              child: Text(l10n.renewAll),
            ),
          ),
          for (final loan in loans)
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: _LoanRow(
                loan: loan,
                days: daysTo(loan.due),
                onTap: () =>
                    _showRenew(context, loan, daysTo(loan.due), onRenew),
              ),
            ),
        ],
        if (holds.isNotEmpty) ...[
          SectionLabel('${l10n.holds}・${l10n.recordCount(holds.length)}'),
          for (final hold in holds)
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: _HoldRow(
                hold: hold,
                onTap: () => _confirmCancel(context, hold, onCancel),
              ),
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
          '${l10n.loanDue(monthDay(first.due))}・'
          '${sameDay == 1 ? first.title : l10n.bookCount(sameDay)}',
          style: note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ];
    }
    return ToneBlock(
      tone: tone,
      radius: Corners.card,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...head,
          if (holds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: Space.l),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.m,
                vertical: Space.m,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .1
                      : .55,
                ),
                borderRadius: BorderRadius.circular(Corners.inset),
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
                          l10n.heldUntil(monthDay(d)),
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
  const _LoanRow({required this.loan, required this.days, required this.onTap});

  final Loan loan;
  final int days;
  final VoidCallback onTap;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.row),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: Space.m,
          ),
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
                        l10n.loanDue(monthDay(loan.due)),
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
              StatusPill(tone: tone, label: label),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoldRow extends StatelessWidget {
  const _HoldRow({required this.hold, required this.onTap});

  final Hold hold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final detail = [
      if (hold.status.isNotEmpty) hold.status,
      if (hold.ready && hold.pickup.isNotEmpty) hold.pickup,
    ].join('・');
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.row),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: Space.m,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hold.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
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
              StatusPill(
                tone: hold.ready
                    ? tones.mint
                    : Tone(
                        scheme.surfaceContainerHigh,
                        scheme.onSurfaceVariant,
                        scheme.onSurfaceVariant,
                      ),
                label: hold.ready ? l10n.holdReady : l10n.holdWaiting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showRenew(
  BuildContext context,
  Loan loan,
  int days,
  ValueChanged<Loan> onRenew,
) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  showGlassSheet<void>(
    context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loan.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          if (loan.author.isNotEmpty)
            Text(
              loan.author,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dueDate),
            trailing: Text(
              '${monthDay(loan.due)}（${days < 0 ? l10n.daysOverdue(-days) : l10n.loanDaysLeft(days)}）',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: loan.renewable
                ? () {
                    Navigator.pop(sheet);
                    onRenew(loan);
                  }
                : null,
            child: Text(loan.renewable ? l10n.renew : l10n.notRenewable),
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmCancel(
  BuildContext context,
  Hold hold,
  ValueChanged<Hold> onCancel,
) async {
  final l10n = context.l10n;
  final cancel = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.cancelHoldTitle),
      content: Text(hold.title),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(l10n.keepHold),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(l10n.cancelHold),
        ),
      ],
    ),
  );
  if (cancel == true) onCancel(hold);
}
