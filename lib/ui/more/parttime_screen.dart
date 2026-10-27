import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/floating_dock.dart';
import '../core/theme.dart';
import '../core/glass_sheet.dart';
import '../core/widgets.dart';
import '../../data/repositories/parttime_data.dart';
import '../core/campus_systems.dart';
import '../core/glass_dialog.dart';

/// design/round-25: a desktop page's title, with its stage and buttons.
Widget _deskHead(
  BuildContext context,
  String title, {
  bool stage = false,
  List<Widget> actions = const [],
}) => Row(
  spacing: 10,
  children: [
    Text(
      title,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
    ),
    if (stage) DeskTag(pageStages['0014']!, color: context.tones.peach.strong),
    const Spacer(),
    ...actions,
  ],
);

/// Design round-11 parttime-screens: the five functions of 學習暨勞僱時數登錄
/// on made-up data (alpha). The app bar button opens the real site.
class ParttimeScreen extends StatefulWidget {
  const ParttimeScreen({super.key});

  @override
  State<ParttimeScreen> createState() => _ParttimeScreenState();
}

String _h(double hours) => hours == hours.roundToDouble()
    ? '${hours.round()}'
    : hours.toStringAsFixed(1);

String _span(HoursEntry e) => '${clock(e.start)}–${clock(e.end)}';

(Tone, String) _statePill(BuildContext context, HoursState s) {
  final tones = context.tones;
  final l10n = context.l10n;
  return switch (s) {
    HoursState.unconfirmed => (tones.sun, l10n.ptUnconfirmed),
    HoursState.confirmed => (tones.mint, l10n.ptConfirmed),
    HoursState.paid => (tones.lilac, l10n.ptPaid),
  };
}

class _ParttimeScreenState extends State<ParttimeScreen> {
  final _store = HoursStore.instance;
  final _keys = {
    for (final k in ['month', 'state', 'unit']) k: GlobalKey(),
  };
  late DateTime? _month = DateTime(clk.clock.now().year, clk.clock.now().month);
  HoursState? _state;
  String? _unit;

  /// Selecting entries to delete; only unconfirmed ones can be.
  Set<String>? _selected;

  Future<T?> _pick<T>(String key, List<(T, String, String?)> options, T now) {
    final box = _keys[key]!.currentContext!.findRenderObject()! as RenderBox;
    return showGlassMenu<T>(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      selected: now,
      items: [
        for (final (value, label, detail) in options)
          (value: value, title: label, detail: detail, icon: null, tone: null),
      ],
    );
  }

  String _monthLabel(DateTime m) => context.l10n.ptMonth(rocYear(m), m.month);

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ids = _selected!;
    final yes = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: l10n.ptDeleteTitle(ids.length),
        content: Text(
          [
            for (final e in _store.entries)
              if (ids.contains(e.id))
                '${dayLabel(context, e.date)} ${_span(e)}・${e.unit}',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ptDelete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    _store.delete(ids);
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final now = clk.clock.now();
    final all = _store.entries;
    final shown = [
      for (final e in all)
        if ((_month == null ||
                (e.date.year == _month!.year &&
                    e.date.month == _month!.month)) &&
            (_unit == null || e.unit == _unit) &&
            (_state == null || e.state == _state))
          e,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final months = {
      for (final e in all) DateTime(e.date.year, e.date.month),
      DateTime(now.year, now.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final units = {for (final e in all) e.unit}.toList();
    final selected = _selected;
    double hoursIn(HoursState s) =>
        shown.where((e) => e.state == s).fold(0, (sum, e) => sum + hoursOf(e));
    final week = weekHours(all, weekOf(now));
    String stateLabel(HoursState? s) =>
        s == null ? l10n.anyStatus : _statePill(context, s).$2;

    final groups = <DateTime, List<HoursEntry>>{};
    for (final e in shown) {
      (groups[e.date] ??= []).add(e);
    }

    final chips = [
      BarChip(
        key: _keys['month'],
        label: _month == null ? l10n.allTime : _monthLabel(_month!),
        selected: _month != null,
        dropdown: true,
        onTap: () async {
          // A far-past date stands for every month in the menu.
          final any = DateTime(0);
          final m = await _pick<DateTime>('month', [
            for (final m in months) (m, _monthLabel(m), null),
            (any, l10n.allTime, null),
          ], _month ?? any);
          if (m != null) setState(() => _month = m == any ? null : m);
        },
      ),
      BarChip(
        key: _keys['state'],
        label: stateLabel(_state),
        selected: _state != null,
        dropdown: true,
        onTap: () async {
          final s = await _pick<int>('state', [
            for (final s in HoursState.values) (s.index, stateLabel(s), null),
            (-1, l10n.anyStatus, null),
          ], _state?.index ?? -1);
          if (s != null) {
            setState(() => _state = s < 0 ? null : HoursState.values[s]);
          }
        },
      ),
      BarChip(
        key: _keys['unit'],
        label: _unit ?? l10n.ptAllUnits,
        selected: _unit != null,
        dropdown: true,
        onTap: () async {
          final u = await _pick<String>('unit', [
            for (final u in units) (u, u, null),
            ('', l10n.ptAllUnits, null),
          ], _unit ?? '');
          if (u != null) setState(() => _unit = u.isEmpty ? null : u);
        },
      ),
    ];
    final select = BarChip(
      label: selected == null ? l10n.ptSelect : l10n.ptDone,
      selected: selected != null,
      onTap: () => setState(() => _selected = selected == null ? {} : null),
    );
    if (desktopUi(context)) {
      return _desk(context, shown, groups, chips, select, hoursIn, week);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        selected == null ? l10n.ptTitle : l10n.ptSelected(selected.length),
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            select,
            const SizedBox(width: 8),
            const SchoolSiteButton('0014'),
          ],
        ),
        bottom: ChipBar(children: chips),
      ),
      body: Builder(
        builder: (context) => PinnedActionList(
          padding: scrollPadding(context),
          action: selected == null
              ? DockButton(
                  onPressed: () => context.push('/more/parttime/add'),
                  tone: tones.lilac,
                  child: Text(l10n.ptAdd),
                )
              : DockButton(
                  onPressed: selected.isEmpty ? null : _delete,
                  tone: tones.peach,
                  child: Text(l10n.ptDeleteCount(selected.length)),
                ),
          children: [
            if (selected == null) ...[
              Row(
                children: [
                  for (final (i, s) in HoursState.values.indexed) ...[
                    if (i > 0) const SizedBox(width: rowGap),
                    Expanded(
                      child: ToneBlock(
                        tone: _statePill(context, s).$1,
                        radius: Corners.row,
                        padding: const EdgeInsets.all(Space.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _h(hoursIn(s)),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${stateLabel(s)}・${l10n.unitHours}',
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
              const SizedBox(height: rowGap),
              Card(
                color: scheme.surfaceContainerLow,
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ptWeek(_h(week), weeklyLimit),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (week / weeklyLimit).clamp(0, 1),
                          minHeight: 8,
                          color: week > weeklyLimit * 0.8
                              ? tones.peach.strong
                              : tones.mint.strong,
                          backgroundColor: scheme.surfaceContainerHigh,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  l10n.ptNoRecords,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final MapEntry(key: day, value: entries)
                in groups.entries) ...[
              SectionLabel(dayLabel(context, day)),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, e) in entries.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _EntryRow(
                        entry: e,
                        selected: selected?.contains(e.id),
                        onTap: selected == null
                            ? null
                            : e.state == HoursState.unconfirmed
                            ? () => setState(
                                () => selected.contains(e.id)
                                    ? selected.remove(e.id)
                                    : selected.add(e.id),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (selected == null) ...[
              SectionLabel(l10n.ptOther),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, (title, path)) in [
                      (l10n.ptPayroll, '/more/parttime/pay'),
                      (l10n.ptPrint, '/more/parttime/print'),
                    ].indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(path),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// design/round-25 parttime: the filters and the three totals under the
  /// title, then the entries by day beside the other pages.
  Widget _desk(
    BuildContext context,
    List<HoursEntry> shown,
    Map<DateTime, List<HoursEntry>> groups,
    List<Widget> chips,
    Widget select,
    double Function(HoursState) hoursIn,
    double week,
  ) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected;
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    final entries = [
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DeskLine(title: l10n.ptNoRecords),
        ),
      for (final MapEntry(key: day, value: list) in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(
            dayLabel(context, day),
            style: muted.copyWith(fontSize: 11, color: scheme.outline),
          ),
        ),
        for (final e in list)
          _EntryRow(
            entry: e,
            selected: selected?.contains(e.id),
            onTap: selected == null || e.state != HoursState.unconfirmed
                ? null
                : () => setState(
                    () => selected.contains(e.id)
                        ? selected.remove(e.id)
                        : selected.add(e.id),
                  ),
          ),
      ],
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptTitle,
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            select,
            const SizedBox(width: 8),
            const SchoolSiteButton('0014'),
          ],
        ),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            _deskHead(
              context,
              selected == null
                  ? l10n.ptTitle
                  : l10n.ptSelected(selected.length),
              stage: selected == null,
              actions: [
                if (selected == null)
                  DeskButton(
                    icon: Icons.add,
                    label: l10n.ptAdd,
                    primary: true,
                    onPressed: () => context.push('/more/parttime/add'),
                  )
                else
                  DeskButton(
                    icon: Icons.delete_outline,
                    label: l10n.ptDeleteCount(selected.length),
                    primary: true,
                    onPressed: selected.isEmpty ? null : _delete,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // A row: the chips size to their labels.
            Row(spacing: 6, children: chips),
            if (selected == null) ...[
              const SizedBox(height: 14),
              Row(
                spacing: Space.s,
                children: [
                  for (final s in HoursState.values)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outlineVariant),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Row(
                              spacing: 6,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _statePill(context, s).$1.strong,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Text(
                                  _statePill(context, s).$2,
                                  style: muted.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text.rich(
                              TextSpan(
                                text: _h(hoursIn(s)),
                                children: [
                                  TextSpan(
                                    text: ' ${l10n.unitHours}',
                                    style: muted,
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: DeskBar(
                      value: week / weeklyLimit,
                      color: week > weeklyLimit * 0.8
                          ? tones.peach.strong
                          : tones.sun.strong,
                    ),
                  ),
                  Text(
                    l10n.ptWeek(_h(week), weeklyLimit),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: entries,
                  ),
                ),
                if (selected == null) ...[
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: DeskSection(
                        title: l10n.ptOther,
                        children: [
                          for (final (icon, title, path) in [
                            (
                              Icons.payments_outlined,
                              l10n.ptPayroll,
                              '/more/parttime/pay',
                            ),
                            (
                              Icons.print_outlined,
                              l10n.ptPrint,
                              '/more/parttime/print',
                            ),
                          ])
                            DeskLine(
                              leading: DeskIcon(icon),
                              title: title,
                              value: '›',
                              valueColor: scheme.outline,
                              onTap: () => context.push(path),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, this.selected, this.onTap});

  final HoursEntry entry;

  /// Null outside selecting.
  final bool? selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final e = entry;
    final (tone, label) = _statePill(context, e.state);
    final selectable = e.state == HoursState.unconfirmed;
    if (desktopUi(context)) {
      return Opacity(
        opacity: selected != null && !selectable ? 0.45 : 1,
        child: DeskLine(
          leading: switch (selected) {
            final on? => Icon(
              on ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: on ? context.tones.lilac.strong : scheme.outline,
            ),
            null => null,
          },
          title: e.work,
          detail: [
            if (isHoliday(e.date)) l10n.ptHoliday,
            _span(e),
            e.unit,
            if (e.batch case final b?) '${l10n.ptBatch} $b',
          ].join('・'),
          value: l10n.ptHours(_h(hoursOf(e))),
          trailing: DeskTag(label, color: tone.strong),
          onTap: onTap,
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: selected != null && !selectable ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: Space.m,
          ),
          child: Row(
            children: [
              if (selected case final on?) ...[
                Icon(
                  on ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: on ? context.tones.lilac.strong : scheme.outline,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_span(e)}・${e.unit}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (isHoliday(e.date)) l10n.ptHoliday,
                        e.work,
                        if (e.batch case final b?) '${l10n.ptBatch} $b',
                      ].join('・'),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.ptHours(_h(hoursOf(e))),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusPill(tone: tone, label: label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 新增: entries gather in a list first, then are saved together, as the
/// site's next.php then todb.php. The rules are checked while filling in.
class ParttimeAddScreen extends StatefulWidget {
  const ParttimeAddScreen({super.key});

  @override
  State<ParttimeAddScreen> createState() => _ParttimeAddScreenState();
}

class _ParttimeAddScreenState extends State<ParttimeAddScreen> {
  final _store = HoursStore.instance;
  final _work = TextEditingController();
  late var _date = DateUtils.dateOnly(clk.clock.now());
  var _unit = myUnits.first;
  var _start = 9 * 60;
  var _end = 12 * 60;
  final _staged = <HoursEntry>[];

  @override
  void dispose() {
    _work.dispose();
    super.dispose();
  }

  HoursEntry get _draft => (
    id: 'draft',
    date: _date,
    unit: _unit,
    start: _start,
    end: _end,
    work: _work.text.trim(),
    state: HoursState.unconfirmed,
    batch: null,
  );

  /// Why the draft cannot be added, if it cannot.
  String? _problem(BuildContext context) {
    final l10n = context.l10n;
    final d = _draft;
    if (d.end <= d.start) return l10n.ptEndAfterStart;
    final clash = overlapOf(d, [..._store.entries, ..._staged]);
    if (clash != null) {
      return l10n.ptOverlap(
        '${dayLabel(context, clash.date)} ${_span(clash)} ${clash.unit}',
      );
    }
    if (!isHoliday(d.date)) {
      final total = weekHours([
        ..._store.entries,
        ..._staged,
        d,
      ], weekOf(d.date));
      if (total > weeklyLimit) return l10n.ptWeekOver(_h(total), weeklyLimit);
    }
    return null;
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(clk.clock.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      // Not ahead of time, and not past the three months that still count.
      firstDate: today.subtract(const Duration(days: loggableDays)),
      lastDate: today,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool start) async {
    final now = start ? _start : _end;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now ~/ 60, minute: now % 60),
    );
    if (t == null) return;
    setState(() {
      if (start) {
        _start = t.hour * 60 + t.minute;
      } else {
        _end = t.hour * 60 + t.minute;
      }
    });
  }

  Future<void> _pickUnit() async {
    final u = await showGlassSheet<String>(
      context,
      tall: true,
      builder: (context) => _UnitSheet(current: _unit),
    );
    if (u != null) setState(() => _unit = u);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final yes = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: l10n.ptSaveTitle(_staged.length),
        content: Text(
          [
            for (final e in _staged)
              '${dayLabel(context, e.date)} ${_span(e)}・${e.unit}',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ptSave),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    _store.save(_staged);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final problem = _problem(context);
    final staged = _staged.fold<double>(0, (sum, e) => sum + hoursOf(e));
    Widget field(
      String label,
      String value,
      VoidCallback onTap, [
      String? end,
    ]) => ListTile(
      leading: SizedBox(
        width: 48,
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: end == null
          ? const Icon(Icons.chevron_right)
          : Text(
              end,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
      onTap: onTap,
    );
    if (desktopUi(context)) return _desk(context, problem, staged);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptAdd,
        action: const SchoolSiteButton('0014'),
      ),
      body: Builder(
        builder: (context) => PinnedActionList(
          padding: scrollPadding(context),
          action: DockButton(
            onPressed: _staged.isEmpty ? null : _save,
            tone: context.tones.lilac,
            child: Text(l10n.ptSaveCount(_staged.length)),
          ),
          children: [
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  field(
                    l10n.ptDate,
                    '${rocYear(_date)}/${_date.month}/${_date.day} '
                    '${weekdayName(context, _date.weekday)}'
                    '${isHoliday(_date) ? '・${l10n.ptHoliday}' : ''}',
                    _pickDate,
                  ),
                  const Divider(height: 1),
                  field(l10n.ptUnit, _unit, _pickUnit),
                  const Divider(height: 1),
                  ListTile(
                    leading: SizedBox(
                      width: 48,
                      child: Text(
                        l10n.ptTime,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        TextButton(
                          onPressed: () => _pickTime(true),
                          child: Text(clock(_start)),
                        ),
                        const Text('–'),
                        TextButton(
                          onPressed: () => _pickTime(false),
                          child: Text(clock(_end)),
                        ),
                      ],
                    ),
                    trailing: Text(
                      _end > _start
                          ? l10n.ptHours(_h((_end - _start) / 60))
                          : '',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.l,
                      Space.xs,
                      Space.l,
                      Space.s,
                    ),
                    child: TextField(
                      controller: _work,
                      maxLength: 80,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.ptWork,
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(top: rowGap),
                child: ToneBlock(
                  tone: tones.peach,
                  radius: Corners.inset,
                  padding: const EdgeInsets.all(Space.m),
                  child: Text(
                    problem,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            const SizedBox(height: rowGap),
            SizedBox(
              height: 48,
              child: FilledButton.tonal(
                onPressed: problem == null && _work.text.trim().isNotEmpty
                    ? () => setState(() {
                        _staged.add(_draft);
                        _work.clear();
                      })
                    : null,
                child: Text(l10n.ptStage),
              ),
            ),
            if (_staged.isNotEmpty) ...[
              SectionLabel(l10n.ptStaged(_staged.length, _h(staged))),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, e) in _staged.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        title: Text(
                          '${dayLabel(context, e.date)} ${_span(e)}・${e.unit}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          [
                            if (isHoliday(e.date)) l10n.ptHoliday,
                            l10n.ptHours(_h(hoursOf(e))),
                            e.work,
                          ].join('・'),
                        ),
                        trailing: IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _staged.removeAt(i)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// design/round-25 parttime-add: the fields in a grid, the staged
  /// entries below; saving is the title's button.
  Widget _desk(BuildContext context, String? problem, double staged) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    Widget field(String name, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(name, style: label),
        child,
      ],
    );
    // A field that opens a picker, drawn as a text field.
    Widget box(List<Widget> children, VoidCallback onTap, {double? width}) =>
        GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: width,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(children: [for (final c in children) c]),
            ),
          ),
        );
    const value = TextStyle(
      fontWeight: FontWeight.w700,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptAdd,
        action: const SchoolSiteButton('0014'),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            _deskHead(
              context,
              l10n.ptAdd,
              actions: [
                DeskButton(
                  icon: Icons.save_outlined,
                  label: l10n.ptSaveCount(_staged.length),
                  primary: true,
                  onPressed: _staged.isEmpty ? null : _save,
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            Row(
              spacing: 14,
              children: [
                Expanded(
                  child: field(
                    l10n.ptDate,
                    box([
                      Text(dayLabel(context, _date), style: value),
                      const Spacer(),
                      if (isHoliday(_date)) DeskTag(l10n.ptHoliday),
                    ], _pickDate),
                  ),
                ),
                Expanded(
                  child: field(
                    l10n.ptUnit,
                    box([
                      Expanded(child: Text(_unit, style: value)),
                      Icon(Icons.expand_more, size: 16, color: scheme.outline),
                    ], _pickUnit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            field(
              l10n.ptTime,
              Row(
                spacing: Space.s,
                children: [
                  box(
                    [Text(clock(_start), style: value)],
                    () => _pickTime(true),
                    width: 110,
                  ),
                  const Text('–'),
                  box(
                    [Text(clock(_end), style: value)],
                    () => _pickTime(false),
                    width: 110,
                  ),
                  if (_end > _start) ...[
                    const SizedBox(width: 6),
                    Text(l10n.ptHours(_h((_end - _start) / 60)), style: label),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            field(
              l10n.ptWork,
              TextField(
                controller: _work,
                maxLength: 80,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Text(
                  problem,
                  style: label.copyWith(color: context.tones.peach.strong),
                ),
              ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: DeskButton(
                icon: Icons.add,
                label: l10n.ptStage,
                onPressed: problem == null && _work.text.trim().isNotEmpty
                    ? () => setState(() {
                        _staged.add(_draft);
                        _work.clear();
                      })
                    : null,
              ),
            ),
            if (_staged.isNotEmpty) ...[
              const SizedBox(height: Space.s),
              SectionLabel(l10n.ptStaged(_staged.length, _h(staged))),
              for (final (i, e) in _staged.indexed)
                DeskLine(
                  title: e.work,
                  detail: [
                    dayLabel(context, e.date),
                    if (isHoliday(e.date)) l10n.ptHoliday,
                    _span(e),
                    e.unit,
                  ].join('・'),
                  value: l10n.ptHours(_h(hoursOf(e))),
                  leading: IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _staged.removeAt(i)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The student's own units first, then every unit, searchable.
class _UnitSheet extends StatefulWidget {
  const _UnitSheet({required this.current});

  final String current;

  @override
  State<_UnitSheet> createState() => _UnitSheetState();
}

class _UnitSheetState extends State<_UnitSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = [
      for (final u in allUnits)
        if (u.contains(_query)) u,
    ];
    Widget unit(String u) => ListTile(
      title: Text(u, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: u == widget.current
          ? Icon(Icons.check, color: context.tones.lilac.strong)
          : null,
      onTap: () => Navigator.pop(context, u),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(pageMargin, 0, pageMargin, Space.xxl),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            hintText: l10n.ptSearchUnits,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (_query.isEmpty) ...[
          SectionLabel(l10n.ptMyUnits),
          for (final u in myUnits) unit(u),
        ],
        SectionLabel(l10n.ptAllUnits),
        for (final u in matches) unit(u),
      ],
    );
  }
}

/// 付款清冊: each case's net pay first, then what was paid and withheld.
class ParttimePayScreen extends StatefulWidget {
  const ParttimePayScreen({super.key});

  @override
  State<ParttimePayScreen> createState() => _ParttimePayScreenState();
}

class _ParttimePayScreenState extends State<ParttimePayScreen> {
  final _key = GlobalKey();
  late var _month = () {
    final last = DateTime(clk.clock.now().year, clk.clock.now().month - 1);
    return (rocYear(last), last.month);
  }();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = clk.clock.now();
    final months = [
      for (var i = 0; i < 12; i++)
        () {
          final m = DateTime(now.year, now.month - i);
          return (rocYear(m), m.month);
        }(),
    ];
    final cases = [
      for (final c in HoursStore.instance.pay)
        if ((c.year, c.month) == _month) c,
    ];
    final monthChip = BarChip(
      key: _key,
      label: l10n.ptMonth(_month.$1, _month.$2),
      selected: true,
      dropdown: true,
      onTap: () async {
        final box = _key.currentContext!.findRenderObject()! as RenderBox;
        final m = await showGlassMenu<(int, int)>(
          context,
          anchor: box.localToGlobal(Offset.zero) & box.size,
          selected: _month,
          items: [
            for (final m in months)
              (
                value: m,
                title: l10n.ptMonth(m.$1, m.$2),
                detail: null,
                icon: null,
                tone: null,
              ),
          ],
        );
        if (m != null) setState(() => _month = m);
      },
    );
    if (desktopUi(context)) return _desk(context, cases, monthChip);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptPayroll,
        action: const SchoolSiteButton('0014'),
        bottom: ChipBar(children: [monthChip]),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            if (cases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  l10n.ptNoRecords,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final c in cases)
              Padding(
                padding: const EdgeInsets.only(bottom: rowGap),
                child: Card(
                  color: scheme.surfaceContainerLow,
                  child: Padding(
                    padding: cardPadding,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.number}・${c.kind}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    c.summary,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  l10n.ptNet,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  grouped(netOf(c)),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        for (final (head, total, rows) in [
                          (
                            l10n.ptGross,
                            grossOf(c),
                            [
                              (l10n.ptWage, c.wage),
                              (l10n.ptEmpLabor, c.employerLabor),
                              (l10n.ptEmpPension, c.employerPension),
                              (l10n.ptEmpHealth, c.employerHealth),
                              (l10n.ptEmpSupp, c.employerSupplement),
                            ],
                          ),
                          (
                            l10n.ptDeduct,
                            deductionsOf(c),
                            [
                              (l10n.ptTax, c.tax),
                              (l10n.ptLabor, c.labor),
                              (l10n.ptPension, c.pension),
                              (l10n.ptHealth, c.health),
                              (l10n.ptSupp, c.supplement),
                              (l10n.ptOtherDeduct, c.otherDeduction),
                            ],
                          ),
                        ]) ...[
                          const Divider(height: 24),
                          for (final (label, value) in [(head, total), ...rows])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: label == head
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        color: label == head
                                            ? scheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    grouped(value),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// design/round-25 parttime-pay: each case a box, its net pay large,
  /// then what was paid and withheld.
  Widget _desk(BuildContext context, List<PayCase> cases, Widget monthChip) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final k = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    Widget card(PayCase c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${c.number}・${c.kind}', style: k),
          const SizedBox(height: 2),
          Text(c.summary, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(l10n.ptNet, style: k),
          Text(
            grouped(netOf(c)),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          for (final (head, total, rows) in [
            (
              l10n.ptGross,
              grossOf(c),
              [
                (l10n.ptWage, c.wage),
                (l10n.ptEmpLabor, c.employerLabor),
                (l10n.ptEmpPension, c.employerPension),
                (l10n.ptEmpHealth, c.employerHealth),
                (l10n.ptEmpSupp, c.employerSupplement),
              ],
            ),
            (
              l10n.ptDeduct,
              deductionsOf(c),
              [
                (l10n.ptTax, c.tax),
                (l10n.ptLabor, c.labor),
                (l10n.ptPension, c.pension),
                (l10n.ptHealth, c.health),
                (l10n.ptSupp, c.supplement),
                (l10n.ptOtherDeduct, c.otherDeduction),
              ],
            ),
          ]) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(bottom: Space.xs),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Text(head, style: k.copyWith(color: scheme.outline)),
                  const Spacer(),
                  Text(
                    grouped(total),
                    style: k.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      grouped(value),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: value == 0 ? scheme.outline : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptPayroll,
        action: const SchoolSiteButton('0014'),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            _deskHead(context, l10n.ptPayroll, actions: [monthChip]),
            const SizedBox(height: Space.l),
            if (cases.isEmpty) DeskLine(title: l10n.ptNoRecords),
            for (var i = 0; i < cases.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 14,
                  children: [
                    Expanded(child: card(cases[i])),
                    Expanded(
                      child: i + 1 < cases.length
                          ? card(cases[i + 1])
                          : const SizedBox.shrink(),
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

/// 列印簽到退表與批號: a unit's confirmed entries by batch; printing stays
/// on the school's site.
class ParttimePrintScreen extends StatefulWidget {
  const ParttimePrintScreen({super.key});

  @override
  State<ParttimePrintScreen> createState() => _ParttimePrintScreenState();
}

class _ParttimePrintScreenState extends State<ParttimePrintScreen> {
  final _key = GlobalKey();
  var _unit = myUnits.first;

  /// The batch shown in the desktop UI; the first when none is picked.
  String? _batch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = context.tones.lilac;
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final batches = <String, List<HoursEntry>>{};
    for (final e in HoursStore.instance.entries) {
      if (e.unit == _unit && e.batch != null) {
        (batches[e.batch!] ??= []).add(e);
      }
    }
    final unitChip = BarChip(
      key: _key,
      label: _unit,
      selected: true,
      dropdown: true,
      onTap: () async {
        final box = _key.currentContext!.findRenderObject()! as RenderBox;
        final u = await showGlassMenu<String>(
          context,
          anchor: box.localToGlobal(Offset.zero) & box.size,
          selected: _unit,
          items: [
            for (final u in myUnits)
              (value: u, title: u, detail: null, icon: null, tone: null),
          ],
        );
        if (u == null) return;
        setState(() {
          _unit = u;
          _batch = null;
        });
      },
    );
    if (desktopUi(context)) {
      return _desk(context, batches, unitChip);
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptPrint,
        action: const SchoolSiteButton('0014'),
        bottom: ChipBar(children: [unitChip]),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            if (batches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  l10n.ptNoRecords,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final MapEntry(key: batch, value: entries)
                in batches.entries) ...[
              ToneBlock(
                tone: tone,
                radius: Corners.card,
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ptBatch,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      batch,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in [
                          l10n.ptEntries(entries.length),
                          l10n.ptHours(
                            _h(entries.fold(0.0, (sum, e) => sum + hoursOf(e))),
                          ),
                          _statePill(context, entries.first.state).$2,
                        ])
                          StatusPill(
                            tone: Tone(
                              Colors.white.withValues(
                                alpha: light ? 0.55 : 0.12,
                              ),
                              tone.ink,
                              tone.ink,
                            ),
                            label: s,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SectionLabel(l10n.ptSheet),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, e) in entries.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        title: Text(
                          dayLabel(context, e.date),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(_span(e)),
                        trailing: Text(
                          l10n.ptHours(_h(hoursOf(e))),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: rowGap),
              FilledButton.tonal(
                onPressed: () => openSchoolSite(context, '0014'),
                child: Text('${l10n.ptOpenSheet} ↗'),
              ),
              const SizedBox(height: rowGap),
            ],
          ],
        ),
      ),
    );
  }

  /// design/round-25 parttime-print: the unit's batches across, then the
  /// picked batch's rows and the way to print it.
  Widget _desk(
    BuildContext context,
    Map<String, List<HoursEntry>> batches,
    Widget unitChip,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    double hours(List<HoursEntry> list) =>
        list.fold(0.0, (sum, e) => sum + hoursOf(e));
    final picked = batches.containsKey(_batch)
        ? _batch!
        : batches.keys.firstOrNull;
    final entries = batches[picked] ?? [];
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    final keys = batches.keys.toList();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.ptPrint,
        action: const SchoolSiteButton('0014'),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            _deskHead(context, l10n.ptPrint, actions: [unitChip]),
            const SizedBox(height: Space.l),
            if (picked == null)
              DeskLine(title: l10n.ptNoRecords)
            else ...[
              for (var i = 0; i < keys.length; i += 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: Row(
                    spacing: Space.s,
                    children: [
                      for (var j = i; j < i + 3; j++)
                        Expanded(
                          child: j >= keys.length
                              ? const SizedBox.shrink()
                              : GestureDetector(
                                  onTap: () => setState(() => _batch = keys[j]),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: keys[j] == picked
                                            ? deskSelection(scheme)
                                            : null,
                                        border: Border.all(
                                          color: keys[j] == picked
                                              ? Colors.transparent
                                              : scheme.outlineVariant,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 2,
                                        children: [
                                          Text(l10n.ptBatch, style: muted),
                                          Text(
                                            keys[j],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${l10n.ptEntries(batches[keys[j]]!.length)}・'
                                            '${l10n.ptHours(_h(hours(batches[keys[j]]!)))}',
                                            style: muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SectionLabel(
                l10n.ptSheet,
                detail:
                    '${l10n.ptBatch} $picked・${l10n.ptEntries(entries.length)}・'
                    '${l10n.ptHours(_h(hours(entries)))}',
              ),
              for (final e in entries)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(
                          dayLabel(context, e.date),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          _span(e),
                          style: muted.copyWith(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.work,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        l10n.ptHours(_h(hoursOf(e))),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.l),
              Align(
                alignment: Alignment.centerLeft,
                child: DeskButton(
                  icon: Icons.print_outlined,
                  label: '${l10n.ptOpenSheet} ↗',
                  primary: true,
                  onPressed: () => openSchoolSite(context, '0014'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
