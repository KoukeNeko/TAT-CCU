import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/school_calendar.dart';
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

const _rowHeight = 46.0;

/// What an event is; each kind has its own color in the grid and the list.
enum _Kind { school, assign, quiz, course, personal, site }

/// eCourse2 events by module, or by Moodle's event type for the rest:
/// course, group and other activities read as course events.
_Kind _kindOf(CalendarEvent e) => switch (e.kind) {
  'assign' => _Kind.assign,
  'quiz' => _Kind.quiz,
  'user' => _Kind.personal,
  'site' || 'category' => _Kind.site,
  _ => _Kind.course,
};

extension on _Kind {
  // School dates take mint as on the countdown; sun is the selected day.
  Tone tone(Tones t) => switch (this) {
    _Kind.school => t.mint,
    _Kind.assign => t.peach,
    _Kind.quiz => t.identity[9],
    _Kind.course => t.identity[2],
    _Kind.personal => t.identity[6],
    _Kind.site => t.identity[1],
  };

  String label(AppLocalizations l10n) => switch (this) {
    _Kind.school => l10n.schoolCalendar,
    _Kind.assign => l10n.eventLabel('assign', ''),
    _Kind.quiz => l10n.eventLabel('quiz', ''),
    _Kind.course => l10n.eventLabel('course', ''),
    _Kind.personal => l10n.eventLabel('user', ''),
    _Kind.site => l10n.eventLabel('site', ''),
  };
}

/// School calendar entries on [day], counting every day of a range.
List<SchoolDate> _schoolOn(DateTime day) => [
  for (final d in schoolCalendar)
    if (!day.isBefore(d.start) && !day.isAfter(d.end ?? d.start)) d,
];

class _CalendarScreenState extends State<CalendarScreen> {
  final _today = DateUtils.dateOnly(DateTime.now());
  late DateTime _selected = _today;
  late int _page = _pageOf(_today);
  late final _pages = PageController(initialPage: _page);

  /// Each month's events: the saved answer at once, then eCourse2's.
  final _months = <int, List<CalendarEvent>>{};
  final _errors = <int, Object>{};
  final _loads = <int, StreamSubscription<List<CalendarEvent>>>{};

  @override
  void initState() {
    super.initState();
    _load(_page);
  }

  @override
  void dispose() {
    for (final s in _loads.values) {
      s.cancel();
    }
    _pages.dispose();
    super.dispose();
  }

  /// Loads [page] and the months beside it, once each; a failed month is
  /// dropped so coming back to it tries again.
  void _load(int page) {
    final repo = context.read<EcourseRepository>();
    for (final p in [page, page - 1, page + 1]) {
      if (_loads.containsKey(p)) continue;
      _loads[p] = repo
          .watch((r) => r.monthEvents(_monthOf(p)))
          .listen(
            (events) {
              if (!mounted) return;
              setState(() {
                _months[p] = events;
                _errors.remove(p);
              });
            },
            onError: (Object e) {
              if (!mounted) return;
              setState(() => _errors[p] = e);
              _loads.remove(p);
            },
          );
    }
  }

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
                        onPageChanged: (p) {
                          setState(() => _page = p);
                          _load(p);
                        },
                        itemBuilder: (context, page) => _MonthGrid(
                          month: _monthOf(page),
                          today: _today,
                          selected: _selected,
                          events: _months[page] ?? const [],
                          onTap: _select,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Legend(month: month, events: _months[_page] ?? const []),
            _DayEvents(
              key: ValueKey(_selected),
              day: _selected,
              events: _months[_pageOf(_selected)],
              error: _errors[_pageOf(_selected)],
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
      byDay.putIfAbsent(DateUtils.dateOnly(e.time), () => []).add(e);
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
                        final kinds = {
                          if (_schoolOn(day).isNotEmpty) _Kind.school,
                          for (final e in byDay[day] ?? const <CalendarEvent>[])
                            _kindOf(e),
                        };
                        return _DayCell(
                          day: day,
                          inMonth: inMonth,
                          isToday: day == today,
                          isSelected: isSelected,
                          dots: [
                            for (final k in kinds.take(3)) k.tone(tones).strong,
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
  const _DayEvents({
    super.key,
    required this.day,
    required this.events,
    required this.error,
  });

  final DateTime day;

  /// Null while the month is loading.
  final List<CalendarEvent>? events;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final theme = Theme.of(context);
    return Builder(
      builder: (context) {
        final events = [
          for (final e in this.events ?? const <CalendarEvent>[])
            if (DateUtils.dateOnly(e.time) == day) e,
        ]..sort((a, b) => a.time.compareTo(b.time));
        final school = _schoolOn(day);
        final count = school.length + events.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(
              '${day.month}/${day.day} ${weekdayName(context, day.weekday)}',
              detail: count == 0 ? null : context.l10n.itemCount(count),
            ),
            for (final d in school)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ToneBlock(
                  tone: _Kind.school.tone(tones),
                  radius: Corners.row,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          _Kind.school.label(context.l10n),
                          if (d.end case final end?)
                            '${monthDay(d.start)} – ${monthDay(end)}',
                        ].join('・'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (error != null && this.events == null)
              Text('$error', textAlign: TextAlign.center)
            else if (this.events == null)
              const Center(child: CircularProgressIndicator())
            else if (count == 0)
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
                  tone: _kindOf(e).tone(tones),
                  radius: Corners.row,
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

/// The colors in use this month and what they mean.
class _Legend extends StatelessWidget {
  const _Legend({required this.month, required this.events});

  final DateTime month;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final last = DateTime(month.year, month.month + 1, 0);
    final kinds = {
      if (schoolCalendar.any(
        (d) => !d.start.isAfter(last) && !(d.end ?? d.start).isBefore(month),
      ))
        _Kind.school,
      for (final e in events) _kindOf(e),
    };
    if (kinds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final k in _Kind.values)
            if (kinds.contains(k))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: k.tone(tones).strong,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    k.label(context.l10n),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
