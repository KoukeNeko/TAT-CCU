import 'dart:async';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/bus_timetable.dart';
import '../../../l10n/l10n.dart';
import '../../core/desk_list.dart';
import '../../core/desktop_mode.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Design T2 (design/round-11/bus-timetable-variants.html): the next
/// departure of every route and direction, soonest first; then every
/// route past the school, opening to its day's departures, fares and the
/// highway bureau's page. Times are the timetable's departures from the
/// start of each route (assets/bus_timetable.txt), not arrivals.
// shortcut: timetable only; live arrivals need TDX credentials and a relay
// to keep them off devices (research_notes/…/yunbus_api.md).
class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  static const _livePage =
      'https://www.taiwanbus.tw/eBUSPage/Query/QueryResult.aspx';

  final _timetable = loadBusTimetable();
  late final Timer _tick;
  String? _open;

  @override
  void initState() {
    super.initState();
    // The countdowns move on by the minute.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tones;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.toolBus),
      body: Builder(
        builder: (context) => FutureBuilder(
          future: _timetable,
          builder: (context, snapshot) {
            final timetable = snapshot.data;
            if (timetable == null) return const SizedBox.shrink();
            final now = clk.clock.now();
            final palette = [t.lilac, t.identity[2], t.mint, t.identity[6]];
            final tones = {
              for (final (i, r) in timetable.routes.indexed)
                r.number: palette[i % palette.length],
            };
            final next = nextDepartures(timetable.trips, now)
              ..sort((a, b) => a.at.compareTo(b.at));
            final scheme = Theme.of(context).colorScheme;
            final desk = desktopUi(context);
            // design/round-25 bus: the first route stands open.
            final openRoute =
                _open ?? (desk ? timetable.routes.firstOrNull?.number : null);
            return ListView(
              padding: scrollPadding(context, top: desk ? pageTop : 0),
              children: [
                if (desk) ...[
                  Text(
                    l10n.toolBus,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (next.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    DeskSection(
                      title: l10n.busUpNext,
                      children: [
                        for (final (i, d) in next.indexed)
                          _NextRow(
                            departure: d,
                            now: now,
                            tone: tones[d.trip.route]!,
                            first: i == 0,
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                  ],
                  DeskSection(title: l10n.busRoutes, children: const []),
                  const SizedBox(height: 10),
                ] else if (next.isNotEmpty) ...[
                  SectionLabel(l10n.busUpNext),
                  Card(
                    color: scheme.surfaceContainerLow,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, d) in next.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, color: scheme.outlineVariant),
                          _NextRow(
                            departure: d,
                            now: now,
                            tone: tones[d.trip.route]!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (!desk) SectionLabel(l10n.busRoutes),
                for (final route in timetable.routes)
                  Padding(
                    padding: EdgeInsets.only(bottom: desk ? Space.s : rowGap),
                    child: _RouteCard(
                      route: route,
                      timetable: timetable,
                      next: [
                        for (final d in next)
                          if (d.trip.route == route.number) d,
                      ],
                      now: now,
                      tone: tones[route.number]!,
                      open: openRoute == route.number,
                      // '' once the first route is closed: none stands open.
                      onToggle: () => setState(
                        () => _open = openRoute == route.number
                            ? ''
                            : route.number,
                      ),
                      onLive: () => launchUrl(
                        Uri.parse('$_livePage?rno=${route.code}'),
                        mode: LaunchMode.inAppBrowserView,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// How long until [at]: minutes within the hour, hours within the day,
/// else the date, as (value, unit).
List<String> busCountdown(BuildContext context, DateTime at, DateTime now) {
  final l10n = context.l10n;
  final days = DateUtils.dateOnly(at)
      .difference(DateUtils.dateOnly(now))
      .inDays;
  final minutes = at.difference(now).inMinutes + 1;
  if (days == 0 && minutes < 60) return ['$minutes', l10n.unitMinutesLater];
  if (days == 0) return ['${minutes ~/ 60}', l10n.unitHoursLater];
  if (days == 1) return [l10n.tomorrow];
  return [monthDay(at), weekdayName(context, at.weekday)];
}

/// `15:45`, `明天 5:55` or `週六 8:00`.
String _when(BuildContext context, DateTime at, DateTime now) {
  final time = clock(at.hour * 60 + at.minute);
  return switch (DateUtils.dateOnly(at)
      .difference(DateUtils.dateOnly(now))
      .inDays) {
    0 => time,
    1 => '${context.l10n.tomorrow} $time',
    _ => '${monthDay(at)} ${weekdayName(context, at.weekday)} $time',
  };
}

/// A direction's next departure: route, where it starts, the time and how
/// long until then. Departures past today read faint.
class _NextRow extends StatelessWidget {
  const _NextRow({
    required this.departure,
    required this.now,
    required this.tone,
    this.first = false,
  });

  final ({BusTrip trip, DateTime at}) departure;
  final DateTime now;
  final Tone tone;

  /// The soonest, its countdown lit in the desktop UI.
  final bool first;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trip = departure.trip;
    final at = departure.at;
    final today = DateUtils.isSameDay(at, now);
    if (desktopUi(context)) {
      final muted = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: scheme.onSurfaceVariant,
      );
      return Opacity(
        opacity: today ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              _RouteBadge(number: trip.route, tone: tone),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.direction,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${trip.stop}${context.l10n.busDepartsShort}',
                      style: muted.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Text(
                today
                    ? clock(at.hour * 60 + at.minute)
                    : _when(context, at, now),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(
                width: 78,
                child: today
                    ? Text(
                        busCountdown(context, at, now).join(' '),
                        textAlign: TextAlign.right,
                        style: first
                            ? muted.copyWith(color: context.tones.mint.strong)
                            : muted,
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }
    return Opacity(
      opacity: today ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.m,
        ),
        child: Row(
          children: [
            _RouteBadge(number: trip.route, tone: tone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.direction,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${trip.stop}${context.l10n.busDepartsShort}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  today
                      ? clock(at.hour * 60 + at.minute)
                      : _when(context, at, now),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (today)
                  Text(
                    busCountdown(context, at, now).join(' '),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.number, required this.tone});

  final String number;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    if (desktopUi(context)) {
      return Container(
        constraints: const BoxConstraints(minWidth: 52),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.strong.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          number,
          style: TextStyle(
            color: tone.strong,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: Space.s),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: tone.ink,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// A route's row; open, the day's departures per direction, its fares and
/// the highway bureau's live page.
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.timetable,
    required this.next,
    required this.now,
    required this.tone,
    required this.open,
    required this.onToggle,
    required this.onLive,
  });

  final BusRoute route;
  final BusTimetable timetable;
  final List<({BusTrip trip, DateTime at})> next;
  final DateTime now;
  final Tone tone;
  final bool open;
  final VoidCallback onToggle, onLive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(now);
    final startsOn = timetable.trips
        .where((t) => t.route == route.number)
        .map((t) => t.startsOn)
        .nonNulls
        .where((d) => d.isAfter(today))
        .firstOrNull;
    final summary = startsOn != null
        ? l10n.busStartsOn(monthDay(startsOn))
        : next.isEmpty
        ? l10n.busNoTrips
        : [
            for (final d in next)
              '${d.trip.direction} ${busCountdown(context, d.at, now).join(' ')}',
          ].join('・');
    final fares = timetable.fares.where((f) => f.route == route.number);
    final note = timetable.notes[route.number];
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    if (desktopUi(context)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    _RouteBadge(number: route.number, tone: tone),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        route.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (open)
                      DeskButton(
                        icon: Icons.directions_bus_outlined,
                        label: '${l10n.busLive} ↗',
                        onPressed: onLive,
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: scheme.outline,
                      ),
                  ],
                ),
              ),
            ),
            if (open) ...[
              if (next.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.m),
                  child: Text(summary, style: muted),
                ),
              for (final d in next) ...[
                const SizedBox(height: Space.m),
                Text(
                  l10n.busDirectionFrom(d.trip.direction, d.trip.stop),
                  style: muted,
                ),
                const SizedBox(height: 6),
                _DayChips(
                  trips: [
                    for (final t in timetable.trips)
                      if (t.route == route.number &&
                          t.direction == d.trip.direction &&
                          runsOn(t, DateUtils.dateOnly(d.at)))
                        t,
                  ],
                  next: d.trip,
                  passed: DateUtils.isSameDay(d.at, now),
                  now: now,
                  tone: tone,
                ),
              ],
              if (fares.isNotEmpty || note != null) const SizedBox(height: 12),
              if (fares.isNotEmpty)
                Text(
                  '${l10n.busFares}　${[for (final f in fares) '${f.stop} NT\$ ${f.full}／${f.half}'].join('、')}',
                  style: muted.copyWith(fontWeight: FontWeight.w700),
                ),
              if (note != null) Text(note, style: muted),
            ],
          ],
        ),
      );
    }
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.row),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: cardPadding,
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 52),
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: Space.s),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tone.fill,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        route.number,
                        style: TextStyle(
                          color: tone.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(summary, style: muted),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.l,
                  0,
                  Space.l,
                  Space.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in next) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: Space.xs,
                          bottom: Space.s,
                        ),
                        child: Text(
                          l10n.busDirectionFrom(d.trip.direction, d.trip.stop),
                          style: muted,
                        ),
                      ),
                      _DayChips(
                        trips: [
                          for (final t in timetable.trips)
                            if (t.route == route.number &&
                                t.direction == d.trip.direction &&
                                runsOn(t, DateUtils.dateOnly(d.at)))
                              t,
                        ],
                        next: d.trip,
                        // The next bus's day; earlier ones have gone.
                        passed: DateUtils.isSameDay(d.at, now),
                        now: now,
                        tone: tone,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (fares.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: Space.s,
                          bottom: Space.xs,
                        ),
                        child: Row(
                          children: [
                            Text(l10n.busFares, style: muted),
                            const Spacer(),
                            Text(l10n.busFareKinds, style: muted),
                          ],
                        ),
                      ),
                      for (final (i, f) in fares.indexed) ...[
                        if (i > 0)
                          Divider(height: 1, color: scheme.outlineVariant),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Space.s,
                          ),
                          child: Row(
                            children: [
                              Text(
                                f.stop,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${f.full}／${f.half}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.s),
                        child: Text(note, style: muted),
                      ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: onLive,
                      child: Text('${l10n.busLive} ↗'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A direction's departures on one day: gone ones faint, the next lit.
class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.trips,
    required this.next,
    required this.passed,
    required this.now,
    required this.tone,
  });

  final List<BusTrip> trips;
  final BusTrip next;
  final bool passed;
  final DateTime now;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minute = now.hour * 60 + now.minute;
    final times = [for (final t in trips) t.time]..sort();
    if (desktopUi(context)) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final time in times)
            if (passed && time <= minute && time != next.time)
              _deskTime(time, scheme.outline, null, scheme.outlineVariant)
            else if (time == next.time)
              _deskTime(time, scheme.onSurface, deskSelection(scheme), null)
            else
              _deskTime(
                time,
                scheme.onSurface,
                scheme.surfaceContainerHigh,
                null,
              ),
        ],
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final time in times)
          Opacity(
            opacity: passed && time <= minute ? 0.4 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: time == next.time
                    ? tone.strong
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Corners.small),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.m,
                  vertical: Space.s,
                ),
                child: Text(
                  clock(time),
                  style: TextStyle(
                    color: time == next.time
                        ? tone.fill
                        : scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _deskTime(int time, Color ink, Color? fill, Color? edge) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(
      color: fill,
      border: edge == null ? null : Border.all(color: edge),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        clock(time),
        style: TextStyle(
          color: ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
