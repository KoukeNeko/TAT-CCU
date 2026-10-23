import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/demo_data.dart';
import '../../data/services/dorm_net_data.dart';
import '../../l10n/l10n.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/campus_systems.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Design round-16 dormnet A: today's traffic as the hero with the bed, a
/// summary in four tiles, then the offices, disconnections, devices, fee,
/// rules, announcements and help. Read only; applying, paying, devices and
/// reconnecting open the site, signed in.
class DormNetScreen extends StatefulWidget {
  static const cacheKey = 'dorm-net';

  const DormNetScreen({super.key});

  @override
  State<DormNetScreen> createState() => _DormNetScreenState();
}

class _DormNetScreenState extends State<DormNetScreen>
    with AutoRefresh, CampusPageState {
  // The info site writes these in Chinese and English.
  late final _english = Localizations.localeOf(context).languageCode == 'en';
  late final _notices = dormNetNotices(english: _english);
  late final _offices = dormNetOffices(english: _english);

  @override
  String get cacheKey => DormNetScreen.cacheKey;

  void _site(String path, String title) =>
      openCampusPage(context, '$dormNetHome$path', title);

  void _web(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// `明天 13:00`, `週一 19:00`.
  String _when(BuildContext context, DateTime now, DateTime at) {
    final days = DateTime(
      at.year,
      at.month,
      at.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final day = switch (days) {
      0 => context.l10n.today,
      1 => context.l10n.tomorrow,
      _ => weekdayName(context, at.weekday),
    };
    return '$day ${clock(at.hour * 60 + at.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final saved = json;
    return CampusSession(
      key: session,
      title: context.l10n.dormNetTitle,
      entry: dormNetHome,
      host: dormNetHost,
      loadOnStart: false,
      via: const ['portal.dorm.ccu.edu.tw/sso.php'],
      action: const SchoolSiteButton('0065'),
      script: () => readDormNet,
      demo: DemoCampus.dormNet,
      onMessage: received,
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : saved == null
          ? null
          : Builder(
              builder: (context) => PullRefresh(
                onRefresh: () async => session.currentState?.refresh(),
                child: _body(context, dormNetOf(saved)),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, DormNet d) {
    final l10n = context.l10n;
    final tones = context.tones;
    final now = clk.clock.now();
    final fee = dormNetFeeRow(now);
    final paid = d.applied && d.suspended == null;
    // The disconnection still running, and how many of its kind there were.
    final current = d.breaks.where((b) => b.until == null).firstOrNull;
    final times = current == null
        ? 0
        : d.breaks
              .where((b) => current.virus ? b.virus : b.kind == current.kind)
              .length;
    // Built only where shown: reading the list starts its request.
    List<Widget> offices() => [
      SectionLabel(l10n.dormNetOffices),
      FutureBuilder(
        future: _offices,
        builder: (context, snapshot) => _Rows(
          rows: [
            if (snapshot.hasError)
              _Row(title: l10n.loadFailed)
            else if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.all(Space.l),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final o in snapshot.data!)
                _Row(
                  title: o.name,
                  detail: [
                    if (o.ext case final ext?) '#$ext',
                    o.hours,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  trailing: dormNetOfficeOpen(now, o)
                      ? _Pill(l10n.dormNetOpenNow, tones.mint)
                      : _Faint(switch (dormNetOfficeNext(now, o)) {
                          final opens? => _when(context, now, opens),
                          null => l10n.dormNetClosed,
                        }),
                ),
            _Row(
              title: l10n.dormNetMeet,
              detail: l10n.dormNetMeetHours,
              onTap: () => _web('https://meet.google.com/ipw-zahi-ouj'),
            ),
          ],
        ),
      ),
    ];
    List<Widget> news() => [
      SectionLabel(l10n.dormNetNews),
      FutureBuilder(
        future: _notices,
        builder: (context, snapshot) => _Rows(
          rows: [
            if (snapshot.hasError)
              _Row(title: l10n.loadFailed)
            else if (!snapshot.hasData)
              const Padding(
                padding: EdgeInsets.all(Space.l),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final n in snapshot.data!.take(3))
                _Row(
                  title: n.title,
                  detail: n.date == null ? null : monthDay(n.date!),
                  inApp: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => _NoticePage(notice: n),
                    ),
                  ),
                ),
          ],
        ),
      ),
    ];
    return ListView(
      padding: scrollPadding(context),
      children: [
        if (d.suspended case final reason?) ...[
          _Hero(
            tone: tones.peach,
            label: current == null
                ? l10n.dormNetSuspended
                : '${l10n.dormNetSuspended} · $reason',
            title: current == null ? reason : l10n.dormNetNth(times),
            detail: [
              if (current?.from case final from?)
                l10n.dormNetBreakSince(monthDayTime(from)),
              if (current?.virus ?? false)
                l10n.dormNetPenalty(dormNetPenaltyDays(times)),
            ].join(' · '),
            badge: d.bed,
            action: (
              l10n.dormNetUnsuspend,
              () => _site('violations', l10n.dormNetUnsuspend),
            ),
          ),
          if (current?.virus ?? false) ...[
            const SizedBox(height: rowGap),
            _Rows(
              rows: [
                _Row(
                  title: l10n.dormNetAllStopped,
                  detail: l10n.dormNetUnsuspendHint,
                ),
              ],
            ),
          ],
        ] else if (!d.applied)
          _Hero(
            tone: tones.lilac,
            label: d.term ?? '',
            title: l10n.dormNetNotApplied,
            detail: [
              if (d.lastBed case final bed?) l10n.dormNetLastBed(bed),
              l10n.dormNetFeeUntil(
                '${fee.fall ? 'fall' : 'spring'}${fee.row}',
                dormNetFees[fee.row],
              ),
            ].join(' · '),
            action: (
              l10n.dormNetApply,
              () => _site('apply', l10n.dormNetApply),
            ),
          )
        else
          _TrafficHero(usage: d.usage, bed: d.bed),
        const SizedBox(height: rowGap),
        if (!d.applied && d.suspended == null)
          _Tiles(
            tiles: [
              (l10n.dormNetTraffic, '—', l10n.dormNetAfterApply),
              (
                l10n.dormNetCards,
                '${d.cards.length} / $dormNetCards',
                l10n.dormNetOnApply,
              ),
            ],
            onTap: const [null, null],
          )
        else
          _Tiles(
            tiles: [
              (
                d.term ?? l10n.dormNetTitle,
                d.state ?? l10n.dormNetNotApplied,
                d.bed ?? '',
              ),
              (
                l10n.dormNetWifi,
                '${d.wifi} / $dormNetWifi',
                '${l10n.dormNetEditDevices} ↗',
              ),
              (
                l10n.dormNetCards,
                '${d.cards.length} / $dormNetCards',
                d.cards.firstOrNull ?? '',
              ),
              (
                l10n.dormNetBreaks,
                d.breaks.isEmpty
                    ? l10n.dormNetNone
                    : l10n.dormNetTimes(d.breaks.length),
                d.breaks.isEmpty
                    ? ''
                    : '${d.breaks.first.from == null ? '' : monthDay(d.breaks.first.from!)} ${d.breaks.first.kind}',
              ),
            ],
            onTap: [
              null,
              () => _site('dashboard', l10n.dormNetEditDevices),
              () => _site('settings/mac', l10n.dormNetEditCards),
              null,
            ],
          ),
        if (d.suspended == null) ...offices(),
        if (!d.applied && d.suspended == null) ...news(),
        if (paid) ...[
          SectionLabel(
            l10n.dormNetBreaks,
            detail: d.breaks.isEmpty ? null : '${d.breaks.length}',
          ),
          _Rows(
            rows: [
              if (d.breaks.isEmpty)
                _Row(title: l10n.dormNetNone)
              else
                for (final b in d.breaks)
                  _Row(
                    mark: ('毒', tones.peach),
                    title: b.kind,
                    detail: b.from == null
                        ? null
                        : b.until == null
                        ? l10n.dormNetBreakSince(monthDayTime(b.from!))
                        : l10n.dormNetBreakTime(
                            monthDayTime(b.from!),
                            monthDayTime(b.until!),
                          ),
                    trailing: b.until == null
                        ? _Pill(l10n.dormNetStillOff, tones.peach)
                        : _Faint(l10n.dormNetRestored),
                  ),
            ],
          ),
          SectionLabel(l10n.dormNetDevices, detail: l10n.dormNetDevicesNote),
          _Rows(
            rows: [
              for (final mac in d.cards)
                _Row(
                  mark: ('線', tones.identity[3]),
                  title: mac,
                  detail: l10n.dormNetWired,
                ),
              _Row(
                mark: ('W', tones.lilac),
                title: l10n.dormNetWifiOf(d.wifi, dormNetWifi),
                detail: l10n.dormNetPrivateMac,
                onTap: () => _site('dashboard', l10n.dormNetEditDevices),
              ),
              _Row(
                title: l10n.dormNetEditCards,
                onTap: () => _site('settings/mac', l10n.dormNetEditCards),
              ),
            ],
          ),
          SectionLabel(l10n.dormNetFee),
          _Rows(
            rows: [
              _FeeTable(fall: fee.fall, current: fee.row),
              _Row(
                title: l10n.dormNetSlip,
                detail: l10n.dormNetSlipHint,
                onTap: () => _site('payment', l10n.dormNetSlip),
              ),
              _Row(
                title: l10n.dormNetReceipt,
                detail: l10n.dormNetReceiptHint,
                onTap: () => _site('upload', l10n.dormNetReceipt),
              ),
            ],
          ),
          SectionLabel(l10n.dormNetRules),
          for (final pair in [
            [
              (l10n.dormNetRuleTraffic, l10n.dormNetRuleTrafficHint),
              (l10n.dormNetRuleVirus, l10n.dormNetRuleVirusHint),
            ],
            [
              (l10n.dormNetRuleShare, l10n.dormNetRuleShareHint),
              (l10n.dormNetRuleMove, l10n.dormNetRuleMoveHint),
            ],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, (title, body)) in pair.indexed) ...[
                      if (i > 0) const SizedBox(width: rowGap),
                      Expanded(
                        child: _Tile(
                          label: null,
                          value: title,
                          detail: body,
                          small: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ...news(),
          SectionLabel(l10n.dormNetHelp),
          _Rows(
            rows: [
              _Row(
                title: l10n.dormNetTutorial,
                detail: l10n.dormNetTutorialHint,
                onTap: () => _web('https://www.dorm.ccu.edu.tw/tutorial'),
              ),
              _Row(
                title: l10n.dormNetFaq,
                onTap: () => _web('https://www.dorm.ccu.edu.tw/QA'),
              ),
              _Row(
                title: l10n.dormNetReport,
                detail: l10n.dormNetReportHint,
                onTap: () => _web('https://osticket.dorm.ccu.edu.tw/open.php'),
              ),
            ],
          ),
        ],
        if (savedAt case final time?) UpdatedAt(time),
      ],
    );
  }
}

/// Today's traffic against the daily allowance, with the bed on a cookie.
class _TrafficHero extends StatelessWidget {
  const _TrafficHero({required this.usage, required this.bed});

  final double usage;
  final String? bed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = context.tones.mint;
    final share = (usage / dormNetDailyGiB).clamp(0.0, 1.0);
    final left = (dormNetDailyGiB - usage).clamp(0, dormNetDailyGiB);
    return _HeroFrame(
      tone: tone,
      badge: bed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dormNetToday, style: _label),
          const SizedBox(height: Space.s),
          Text.rich(
            TextSpan(
              text: usage.toStringAsFixed(1),
              children: [
                TextSpan(
                  text: ' / $dormNetDailyGiB GiB',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: Space.l),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 12,
              color: tone.ink,
              backgroundColor: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Text(l10n.dormNetOk, style: _meta),
              const Spacer(),
              Text(l10n.dormNetLeft(left.toStringAsFixed(1)), style: _meta),
            ],
          ),
        ],
      ),
    );
  }
}

const _label = TextStyle(fontSize: 13, fontWeight: FontWeight.w900);
const _meta = TextStyle(fontSize: 12, fontWeight: FontWeight.w800);

/// The term's state in place of traffic: not applied, or cut off.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.tone,
    required this.label,
    required this.title,
    required this.detail,
    required this.action,
    this.badge,
  });

  final Tone tone;
  final String label, title, detail;
  final String? badge;
  final (String, VoidCallback) action;

  @override
  Widget build(BuildContext context) => _HeroFrame(
    tone: tone,
    badge: badge,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label),
        const SizedBox(height: Space.s),
        Text(
          title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: Space.xs),
        Text(detail, style: _meta.copyWith(height: 1.4)),
        const SizedBox(height: Space.l),
        PressFeedback(
          scale: 0.97,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tone.strong,
              foregroundColor: tone.fill,
            ),
            onPressed: action.$2,
            child: Text('${action.$1} ↗'),
          ),
        ),
      ],
    ),
  );
}

class _HeroFrame extends StatelessWidget {
  const _HeroFrame({required this.tone, required this.child, this.badge});

  final Tone tone;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) => ToneBlock(
    tone: tone,
    padding: EdgeInsets.zero,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: tone.ink),
      child: Stack(
        children: [
          if (badge case final bed?)
            Positioned(
              right: Space.l,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: tone.strong,
                    shape: scallop,
                  ),
                  child: Text(
                    bed.replaceFirst('-', '\n-'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tone.fill,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: cardPadding.copyWith(
              right: badge == null ? null : 88 + Space.l + Space.m,
            ),
            child: child,
          ),
        ],
      ),
    ),
  );
}

/// The summary: two rows of two tiles.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.tiles, required this.onTap});

  final List<(String, String, String)> tiles;
  final List<VoidCallback?> onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var r = 0; r < tiles.length; r += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: rowGap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = r; i < r + 2 && i < tiles.length; i++) ...[
                  if (i > r) const SizedBox(width: rowGap),
                  Expanded(
                    child: _Tile(
                      label: tiles[i].$1,
                      value: tiles[i].$2,
                      detail: tiles[i].$3,
                      onTap: onTap[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.detail,
    this.onTap,
    this.small = false,
  });

  final String? label;
  final String value, detail;
  final VoidCallback? onTap;

  /// A rule: the value as a heading over its text.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mute = TextStyle(
      fontSize: 12,
      fontWeight: small ? FontWeight.w700 : FontWeight.w800,
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Corners.row),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: Space.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label case final text?)
                Text(text, style: mute.copyWith(fontWeight: FontWeight.w900)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: small ? 14 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  maxLines: small ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: mute,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card of rows with lines between them.
class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0)
            const Divider(height: 1, indent: Space.l, endIndent: Space.l),
          row,
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.detail,
    this.trailing,
    this.mark,
    this.onTap,
    this.inApp = false,
  });

  final String title;
  final String? detail;
  final Widget? trailing;
  final (String, Tone)? mark;

  /// Opens the site, marked ↗, unless [inApp].
  final VoidCallback? onTap;
  final bool inApp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.m,
        ),
        child: Row(
          children: [
            if (mark case (final text, final tone)) ...[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.fill,
                  borderRadius: BorderRadius.circular(Corners.small),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: tone.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: Space.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  if (detail case final text?)
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing case final widget?) ...[
              const SizedBox(width: Space.s),
              widget,
            ] else if (onTap != null) ...[
              const SizedBox(width: Space.s),
              Icon(
                inApp ? Icons.chevron_right : Icons.north_east,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.tone);

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: ShapeDecoration(color: tone.fill, shape: const StadiumBorder()),
    child: Text(
      text,
      style: TextStyle(
        color: tone.ink,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _Faint extends StatelessWidget {
  const _Faint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// The term's fee and refund by when it is applied for, today's row lit.
class _FeeTable extends StatelessWidget {
  const _FeeTable({required this.fall, required this.current});

  final bool fall;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final lit = context.tones.mint.strong;
    TextStyle style(int? row) => TextStyle(
      fontSize: row == null ? 12 : 13,
      fontWeight: FontWeight.w800,
      color: row == null
          ? scheme.onSurfaceVariant
          : row == current
          ? lit
          : scheme.onSurface,
    );
    TableRow line(int? row, List<String> cells) => TableRow(
      children: [
        for (final (i, cell) in cells.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              cell,
              textAlign: i == 0 ? TextAlign.start : TextAlign.end,
              style: style(row),
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FixedColumnWidth(56),
        },
        children: [
          line(null, [
            l10n.dormNetFeeWhen,
            l10n.dormNetFeePay,
            l10n.dormNetFeeRefund,
          ]),
          for (var r = 0; r < dormNetFees.length; r++)
            line(r, [
              l10n.dormNetFeePeriod('${fall ? 'fall' : 'spring'}$r'),
              '${dormNetFees[r]}',
              dormNetRefunds[r] == 0 ? '—' : '${dormNetRefunds[r]}',
            ]),
        ],
      ),
    );
  }
}

class _NoticePage extends StatelessWidget {
  const _NoticePage({required this.notice});

  final DormNetNotice notice;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: subBar(context, context.l10n.dormNetNews),
    // Builder: the padding reads the glass app bar's height from inside.
    body: Builder(
      builder: (context) => ListView(
        padding: scrollPadding(context),
        children: [
          Text(notice.title, style: Theme.of(context).textTheme.titleLarge),
          if (notice.date case final date?)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                '${date.year}/${date.month}/${date.day}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: Space.l),
          SelectableText(notice.body, style: const TextStyle(height: 1.6)),
        ],
      ),
    ),
  );
}
