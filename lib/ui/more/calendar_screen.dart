import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

/// Month calendar with the selected day's events below
/// (design/round-11, variant K1). Swipe the month card to change month.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// Months are pages counted from January 2000.
int _pageOf(DateTime d) => (d.year - 2000) * 12 + d.month - 1;
DateTime _monthOf(int page) => DateTime(2000 + page ~/ 12, page % 12 + 1);
DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

const _rowHeight = 46.0;

class _CalendarScreenState extends State<CalendarScreen> {
  final _today = _dayOf(DateTime.now());
  late DateTime _selected = _today;
  late int _page = _pageOf(_today);
  late final _pages = PageController(initialPage: _page);
  final _cache = <int, Future<List<CalendarEvent>>>{};

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// One request per month; a failed month is dropped so retry refetches.
  Future<List<CalendarEvent>> _events(int page) => _cache.putIfAbsent(page, () {
    final future = context.read<EcourseRepository>().monthEvents(
      _monthOf(page),
    );
    future.catchError((Object _) {
      _cache.remove(page);
      return <CalendarEvent>[];
    });
    return future;
  });

  void _select(DateTime day) {
    setState(() => _selected = day);
    final page = _pageOf(day);
    if (page != _page) {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = _monthOf(_page);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar(
        month.year == _today.year
            ? context.l10n.monthTitle('${month.month}')
            : context.l10n.yearMonthTitle(month.year, '${month.month}'),
        actions: [
          _RoundAction(
            icon: Icons.today_outlined,
            label: context.l10n.goToToday,
            onTap: () => _select(_today),
          ),
          _RoundAction(
            icon: Icons.chevron_left,
            onTap: () => _pages.previousPage(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutQuart,
            ),
          ),
          _RoundAction(
            icon: Icons.chevron_right,
            onTap: () => _pages.nextPage(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutQuart,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            Card(
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var d = 1; d <= 7; d++)
                          Expanded(
                            child: Text(
                              weekdayShort(context, d),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: _rowHeight * 6,
                      child: PageView.builder(
                        controller: _pages,
                        onPageChanged: (p) => setState(() => _page = p),
                        itemBuilder: (context, page) =>
                            FutureBuilder<List<CalendarEvent>>(
                              future: _events(page),
                              builder: (context, snap) => _MonthGrid(
                                month: _monthOf(page),
                                today: _today,
                                selected: _selected,
                                events: snap.data ?? const [],
                                onTap: _select,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _DayEvents(
              key: ValueKey(_selected),
              day: _selected,
              load: () => _events(_pageOf(_selected)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.label, required this.onTap});

  final IconData icon;

  /// Spoken label for icons that need one.
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: scheme.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: scheme.onSurface, semanticLabel: label),
          ),
        ),
      ),
    );
  }
}

/// Six Monday-first weeks so the card keeps one height across months.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.events,
    required this.onTap,
  });

  final DateTime month, today, selected;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final first = month.subtract(Duration(days: month.weekday - 1));
    final byDay = <DateTime, List<CalendarEvent>>{};
    for (final e in events) {
      byDay.putIfAbsent(_dayOf(e.time), () => []).add(e);
    }
    return Column(
      children: [
        for (var w = 0; w < 6; w++)
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // DateTime arithmetic by calendar days, not hours, so
                        // daylight-saving zones keep midnight.
                        final day = DateTime(
                          first.year,
                          first.month,
                          first.day + w * 7 + d,
                        );
                        final inMonth = day.month == month.month;
                        final isSelected = day == selected;
                        final dots = byDay[day] ?? const [];
                        return _DayCell(
                          day: day,
                          inMonth: inMonth,
                          isToday: day == today,
                          isSelected: isSelected,
                          dots: [
                            for (final e in dots.take(3))
                              tones.forCourse(e.courseId).strong,
                          ],
                          onTap: () => onTap(day),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

const _move = Duration(milliseconds: 320);
const _settle = Curves.easeOutQuart;

/// A day in the grid. No ink ripple: pressing sinks the number, and the
/// selection fills in from the center like the nav bar capsule.
class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.dots,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth, isToday, isSelected;
  final List<Color> dots;
  final VoidCallback onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _pressed = false;

  void _press(bool down) => setState(() => _pressed = down);

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.isSelected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(true),
      onTapCancel: () => _press(false),
      onTapUp: (_) => _press(false),
      onTap: () {
        if (!selected) HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: Semantics(
        button: true,
        selected: selected,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.86 : 1,
              duration: _move,
              curve: _settle,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.isToday)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tones.lilac.strong,
                            width: 2,
                          ),
                        ),
                      ),
                    // Pressing an unselected day shows a faint fill first so
                    // the finger has something under it.
                    AnimatedScale(
                      scale: selected ? 1 : (_pressed ? 0.8 : 0),
                      duration: _move,
                      curve: _settle,
                      child: AnimatedContainer(
                        duration: _move,
                        curve: _settle,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? tones.sun.strong : tones.sun.fill,
                        ),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: _move,
                      curve: _settle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? tones.sun.fill
                            : widget.inMonth
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                      child: Text('${widget.day.day}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in widget.dots)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                      ),
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

class _DayEvents extends StatelessWidget {
  const _DayEvents({super.key, required this.day, required this.load});

  final DateTime day;
  final Future<List<CalendarEvent>> Function() load;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final theme = Theme.of(context);
    return FutureBuilder<List<CalendarEvent>>(
      future: load(),
      builder: (context, snap) {
        final events = [
          for (final e in snap.data ?? const <CalendarEvent>[])
            if (_dayOf(e.time) == day) e,
        ]..sort((a, b) => a.time.compareTo(b.time));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
              child: Row(
                children: [
                  Text(
                    '${day.month}/${day.day} ${weekdayName(context, day.weekday)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (events.isNotEmpty)
                    Text(
                      context.l10n.itemCount(events.length),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (snap.hasError)
              Text('${snap.error}', textAlign: TextAlign.center)
            else if (snap.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  context.l10n.noEventsThisDay,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            for (final e in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ToneBlock(
                  tone: tones.forCourse(e.courseId),
                  radius: 22,
                  padding: const EdgeInsets.all(14),
                  onTap: e.cmid != null && e.courseId != 0
                      ? () => context.push(
                          '/courses/${e.courseId}/modules/${e.cmid}',
                        )
                      : e.url == null
                      ? null
                      : () => openExternal(e.url!),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                e.course,
                                context.l10n.eventLabel(e.kind, e.action),
                              ].where((s) => s.isNotEmpty).join('・'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        clock(e.time.hour * 60 + e.time.minute),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
