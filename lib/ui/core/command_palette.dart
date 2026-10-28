import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../domain/models/course.dart';
import '../../l10n/l10n.dart';
import '../courses/course_detail_screen.dart';
import '../today/due_screen.dart';
import 'campus_systems.dart';
import 'format.dart';
import 'theme.dart';

/// ⌘K on macOS, Ctrl+K elsewhere.
bool _isHotkey(KeyEvent e) =>
    e is KeyDownEvent &&
    e.logicalKey == LogicalKeyboardKey.keyK &&
    (Platform.isMacOS
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed);

/// Opens the palette on its hotkey wherever focus is, even with none.
class CommandPaletteHotkey extends StatefulWidget {
  const CommandPaletteHotkey({
    super.key,
    required this.navigator,
    required this.child,
  });

  /// The router's navigator, whose context the palette opens in.
  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  State<CommandPaletteHotkey> createState() => _CommandPaletteHotkeyState();
}

class _CommandPaletteHotkeyState extends State<CommandPaletteHotkey> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (!_isHotkey(e) || _PaletteState.open) return false;
    final context = widget.navigator.currentContext;
    if (context == null) return false;
    showCommandPalette(context);
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The toolbar's search field, which opens the palette.
class PaletteField extends StatelessWidget {
  const PaletteField({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return Semantics(
      button: true,
      label: context.l10n.search,
      child: GestureDetector(
        onTap: () => showCommandPalette(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 220,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(context.l10n.search, style: muted),
                const Spacer(),
                Text(
                  Platform.isMacOS ? '⌘K' : 'Ctrl K',
                  style: muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showCommandPalette(BuildContext context) => showGeneralDialog(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black.withValues(alpha: 0.32),
  transitionDuration: const Duration(milliseconds: 140),
  transitionBuilder: (context, animation, _, child) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(begin: 0.97, end: 1.0).animate(animation),
      alignment: Alignment.topCenter,
      child: child,
    ),
  ),
  pageBuilder: (dialogContext, _, _) => _Palette(origin: context),
);

typedef _Entry = ({
  String group,
  IconData icon,
  Color? tint,
  String title,
  String? detail,
  String? trailing,
  void Function(BuildContext context) open,
});

class _Palette extends StatefulWidget {
  const _Palette({required this.origin});

  /// Where the palette was opened; pages open from it once it closes.
  final BuildContext origin;

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  /// One palette at a time, though the hotkey can fire under it.
  static var open = false;

  final _query = TextEditingController();
  late final Stream<(List<Course>, List<DueItem>)> _data;
  var _selected = 0;
  var _shown = <_Entry>[];

  @override
  void initState() {
    super.initState();
    open = true;
    _data = context.read<EcourseRepository>().watch(
      (r) async => (await r.currentCourses(), await r.dueSoon(days: 14)),
    );
    _query.addListener(() => setState(() => _selected = 0));
  }

  @override
  void dispose() {
    open = false;
    _query.dispose();
    super.dispose();
  }

  List<_Entry> _entries(List<Course> courses, List<DueItem> due) {
    final l10n = context.l10n;
    final t = context.tones;
    final pages = l10n.palettePages;
    void go(BuildContext c, String path) => c.go(path);
    return [
      for (final c in courses) ...[
        (
          group: l10n.navCourses,
          icon: Icons.menu_book_outlined,
          tint: t.forCourse(c.id).strong,
          title: context.courseName(c),
          detail: c.room,
          trailing: null,
          open: (b) => go(b, '/courses/${c.id}'),
        ),
        for (final part in CoursePart.values.skip(1))
          (
            group: l10n.navCourses,
            icon: part == CoursePart.grades
                ? Icons.bar_chart
                : Icons.campaign_outlined,
            tint: null,
            title: '${context.courseName(c)} › ${part.title(l10n)}',
            detail: null,
            trailing: null,
            open: (b) => go(b, '/courses/${c.id}/${part.name}'),
          ),
      ],
      for (final d in due)
        (
          group: l10n.toDo,
          icon: Icons.assignment_outlined,
          tint: null,
          title: d.name,
          detail: switch (courses.where((c) => c.id == d.courseId)) {
            final found when found.isNotEmpty => context.courseName(
              found.first,
            ),
            _ => context.courseNameOf(d.course),
          },
          trailing: monthDayTime(d.due),
          open: (b) => openDueItem(b, d),
        ),
      for (final (icon, title, path) in [
        (Icons.today_outlined, l10n.navToday, '/today'),
        (Icons.forum_outlined, l10n.navMessages, '/messages'),
        (Icons.calendar_view_week_outlined, l10n.navTimetable, '/timetable'),
        (Icons.event_outlined, l10n.navCalendar, '/calendar'),
        (Icons.apps, l10n.navMore, '/more'),
      ])
        (
          group: pages,
          icon: icon,
          tint: null,
          title: title,
          detail: null,
          trailing: null,
          open: (b) => go(b, path),
        ),
      for (final (_, systems) in campusGroups)
        for (final s in systems)
          (
            group: pages,
            icon: inAppPages.containsKey(s.id)
                ? Icons.chevron_right
                : Icons.north_east,
            tint: null,
            title: s.name,
            detail: s.note,
            trailing: null,
            open: (b) => openCampusSystem(b, s, replace: true),
          ),
      for (final (icon, title, path) in [
        (Icons.handyman_outlined, l10n.tools, '/more/tools'),
        (Icons.person_outline, l10n.account, '/more/account'),
        (Icons.tune, l10n.settings, '/more/settings'),
        (Icons.palette_outlined, l10n.designLanguage, '/more/design'),
        (Icons.info_outline, l10n.about, '/more/about'),
      ])
        (
          group: pages,
          icon: icon,
          tint: null,
          title: title,
          detail: null,
          trailing: null,
          open: (b) => go(b, path),
        ),
    ];
  }

  /// Matching entries, a few per group until something is typed.
  List<_Entry> _filter(List<_Entry> all) {
    final q = _query.text.trim().toLowerCase();
    final perGroup = q.isEmpty ? 4 : 6;
    final counts = <String, int>{};
    return [
      for (final e in all)
        if ((q.isEmpty ||
                e.title.toLowerCase().contains(q) ||
                (e.detail?.toLowerCase().contains(q) ?? false)) &&
            // Course parts only once something is asked for.
            (q.isNotEmpty || !e.title.contains(' › ')) &&
            (counts[e.group] = (counts[e.group] ?? 0) + 1) <= perGroup)
          e,
    ];
  }

  void _openSelected() {
    if (_shown.isEmpty) return;
    final entry = _shown[_selected];
    Navigator.of(context).pop();
    if (widget.origin.mounted) entry.open(widget.origin);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = switch (e.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (step == 0 || _shown.isEmpty) return KeyEventResult.ignored;
    setState(() => _selected = (_selected + step) % _shown.length);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final faint = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 48,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            color: scheme.surfaceContainer,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: SizedBox(
              width: 640,
              child: StreamBuilder(
                stream: _data,
                builder: (context, snap) {
                  final (courses, due) =
                      snap.data ?? (const <Course>[], const <DueItem>[]);
                  _shown = _filter(_entries(courses, due));
                  if (_selected >= _shown.length) _selected = 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Focus(
                        onKeyEvent: _onKey,
                        child: TextField(
                          controller: _query,
                          autofocus: true,
                          onSubmitted: (_) => _openSelected(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.paletteHint,
                            prefixIcon: const Icon(Icons.search),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: scheme.outlineVariant),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 440),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          children: [
                            for (final (i, e) in _shown.indexed) ...[
                              if (i == 0 || _shown[i - 1].group != e.group)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    10,
                                    18,
                                    4,
                                  ),
                                  child: Text(
                                    e.group,
                                    style: faint.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              _Row(
                                entry: e,
                                query: _query.text.trim(),
                                selected: i == _selected,
                                onHover: () => setState(() => _selected = i),
                                onTap: () {
                                  _selected = i;
                                  _openSelected();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      Divider(height: 1, color: scheme.outlineVariant),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Text(
                          '↑ ↓ ${l10n.paletteSelect}    ↵ ${l10n.open}    esc',
                          style: faint,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.query,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  final _Entry entry;
  final String query;
  final bool selected;
  final VoidCallback onHover, onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final faint = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return MouseRegion(
      onEnter: (_) => onHover(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                entry.icon,
                size: 16,
                color: entry.tint ?? scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text.rich(
                        _highlight(entry.title, query, scheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (entry.detail case final detail?) ...[
                      const SizedBox(width: 10),
                      Text(detail, style: faint),
                    ],
                  ],
                ),
              ),
              if (entry.trailing case final trailing?)
                Text(trailing, style: faint),
            ],
          ),
        ),
      ),
    );
  }
}

/// [text] with the first match of [query] in [color].
TextSpan _highlight(String text, String query, Color color) {
  final at = query.isEmpty
      ? -1
      : text.toLowerCase().indexOf(query.toLowerCase());
  if (at < 0) return TextSpan(text: text);
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, at)),
      TextSpan(
        text: text.substring(at, at + query.length),
        style: TextStyle(color: color),
      ),
      TextSpan(text: text.substring(at + query.length)),
    ],
  );
}
