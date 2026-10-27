import 'dart:async';

import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/demo_data.dart';
import '../../l10n/l10n.dart';
import '../core/floating_dock.dart';
import '../core/auto_refresh.dart';
import '../core/campus_session.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../data/services/ecourse_web.dart';
import '../core/segment_switch.dart';
import '../core/glass_dialog.dart';
import 'course_detail_screen.dart';

/// 請假單 (design/round-11 course-modules-screens), shaped like 宿舍維修:
/// the student's own requests, then a button to the full-page form.
class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key, required this.cmid, this.title});

  final int cmid;
  final String? title;

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen>
    with AutoRefresh, CampusPageState {
  var _sending = false;

  @override
  String get cacheKey => 'absences-${widget.cmid}';

  /// The route's course, for the desktop UI's path and heading.
  late final _courseId = int.parse(
    GoRouterState.of(context).pathParameters['id']!,
  );
  late final _name = widget.title != null
      ? Future.value(widget.title)
      : moduleName(context.read<EcourseRepository>(), _courseId, widget.cmid);

  /// A submitted request answers `submitted`; the list then reads again.
  @override
  Future<void> received(Map<String, dynamic> message) async {
    if (message['kind'] == 'submitted') {
      setState(() => _sending = false);
      if (message['ok'] == true) {
        await session.currentState?.reload();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message['error'] ?? context.l10n.loadFailed}'),
          ),
        );
      }
      return;
    }
    if (message['error'] != null) _sending = false;
    await super.received(message);
  }

  Future<void> _new() async {
    if (context.read<EcourseAuthRepository>().isDemo) {
      session.currentState?.run('');
      return;
    }
    final form = AbsenceFormScreen(course: '${json?['course'] ?? ''}');
    // A desktop window opens the form as a sheet over the page.
    final request = desktopUi(context)
        ? await showDialog<AbsenceRequest>(
            context: context,
            builder: (_) => form,
          )
        : await Navigator.of(context)
              .push<AbsenceRequest>(MaterialPageRoute(builder: (_) => form));
    if (request == null || !mounted) return;
    setState(() => _sending = true);
    await session.currentState?.run(submitAbsence(widget.cmid, request));
    // An expired session may never answer; let the button work again.
    Timer(const Duration(seconds: 30), () {
      if (!mounted || !_sending) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.loadFailed)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = json;
    return CampusSession(
      key: session,
      title: widget.title ?? '',
      titleChild: desktopUi(context)
          ? FutureBuilder(
              future: _name,
              builder: (context, name) => CourseCrumbs(
                courseId: _courseId,
                trail: [context.l10n.allSections, name.data ?? ''],
              ),
            )
          : null,
      entry: ecourseEntry,
      host: ecourseHost,
      loadOnStart: false,
      script: () => readAbsences(widget.cmid),
      demo: DemoCampus.absences,
      onMessage: received,
      child: error != null
          ? CampusError(message: error!, onRetry: retry)
          : saved == null
          ? null
          : Builder(builder: (context) => _body(context, saved)),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> json) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final head = [for (final h in json['head'] as List? ?? const []) '$h'];
    final rows = [
      for (final r in (json['rows'] as List? ?? const []).whereType<List>())
        [for (final c in r) '$c'],
    ];
    if (desktopUi(context)) return _desk(context, head, rows);
    return Stack(
      children: [
        Positioned.fill(
          child: PullRefresh(
            onRefresh: () async => session.currentState?.refresh(),
            child: ListView(
              padding: scrollPadding(context)
                  .copyWith(bottom: MediaQuery.paddingOf(context).bottom + 90),
              children: [
                SectionLabel(l10n.absenceHistory, detail: '${rows.length}'),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      l10n.noAbsences,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                else
                  Card(
                    color: scheme.surfaceContainerLow,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, row) in rows.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, color: scheme.outlineVariant),
                          // shortcut: the site's columns are unknown until a
                          // request exists, so each row lists them as label:
                          // value; give it a proper layout once seen.
                          ListTile(
                            title: Text(
                              row.first,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              [
                                for (final (j, cell) in row.indexed.skip(1))
                                  if (cell.isNotEmpty)
                                    j < head.length ? '${head[j]}：$cell' : cell,
                              ].join('\n'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (savedAt case final time?) UpdatedAt(time),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DockButton(
            onPressed: _sending ? null : _new,
            tone: context.tones.lilac,
            child: _sending
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(l10n.absenceNew),
          ),
        ),
      ],
    );
  }

  /// design/round-25: the module's head and its button, then each request
  /// in a box of its fields.
  Widget _desk(
    BuildContext context,
    List<String> head,
    List<List<String>> rows,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final line = BorderSide(color: scheme.outlineVariant);
    return ListView(
      padding: scrollPadding(context),
      children: [
        FutureBuilder(
          future: _name,
          builder: (context, name) => CoursePageHead(
            courseId: _courseId,
            kind: l10n.leave,
            title: name.data ?? '',
          ),
        ),
        const SizedBox(height: Space.l),
        Align(
          alignment: Alignment.centerLeft,
          child: DeskButton(
            icon: Icons.edit_outlined,
            label: l10n.absenceNew,
            primary: true,
            onPressed: _sending ? null : _new,
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel(l10n.absenceHistory, detail: '${rows.length}'),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      l10n.noAbsences,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final row in rows)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.fromLTRB(
                      Space.l,
                      Space.s,
                      Space.l,
                      Space.s,
                    ),
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(line),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(bottom: line),
                          ),
                          child: Text(
                            row.first,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        for (final (j, cell) in row.indexed.skip(1))
                          if (cell.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (j < head.length)
                                    SizedBox(
                                      width: 84,
                                      child: Text(
                                        '${head[j]}：',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      cell,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The site's five fields; pops with the request once confirmed.
class AbsenceFormScreen extends StatefulWidget {
  const AbsenceFormScreen({super.key, required this.course});

  final String course;

  @override
  State<AbsenceFormScreen> createState() => _AbsenceFormScreenState();
}

class _AbsenceFormScreenState extends State<AbsenceFormScreen> {
  final _remark = TextEditingController();
  var _date = DateUtils.dateOnly(clk.clock.now());
  var _type = 0;
  var _online = false;

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  List<String> _types(AppLocalizations l10n) => [
    l10n.absenceType0,
    l10n.absenceType1,
    l10n.absenceType2,
    l10n.absenceType3,
    l10n.absenceType4,
  ];

  Future<void> _pickDate() async {
    final now = clk.clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final request = (
      date: _date,
      type: _type,
      online: _online,
      remark: _remark.text.trim(),
    );
    final yes = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: l10n.absenceSubmitTitle,
        content: Text(
          '${_date.month}/${_date.day} ${weekdayName(context, _date.weekday)}・'
          '${_types(l10n)[_type]}・'
          '${_online ? l10n.absenceOnline : l10n.absenceInPerson}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
    if (yes == true && mounted) Navigator.pop(context, request);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tones = context.tones;
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    Widget row(String label, Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
    const value = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
    if (desktopUi(context)) return _desk(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.absenceNew),
      body: Builder(
        builder: (context) => PinnedActionList(
          padding: scrollPadding(context),
          action: DockButton(
            onPressed: _submit,
            tone: tones.lilac,
            child: Text(l10n.submit),
          ),
          children: [
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  row(l10n.absenceCourse, Text(widget.course, style: value)),
                  const Divider(height: 1),
                  InkWell(
                    onTap: _pickDate,
                    child: row(
                      l10n.absenceDate,
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_date.month}/${_date.day} '
                            '${weekdayName(context, _date.weekday)}',
                            style: value,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  row(
                    l10n.absenceType,
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (i, name) in _types(l10n).indexed)
                          BarChip(
                            label: name,
                            selected: _type == i,
                            tone: tones.peach,
                            onTap: () => setState(() => _type = i),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  row(
                    l10n.absenceMode,
                    SegmentSwitch(
                      labels: [l10n.absenceInPerson, l10n.absenceOnline],
                      selected: _online ? 1 : 0,
                      onChanged: (i) => setState(() => _online = i == 1),
                    ),
                  ),
                  const Divider(height: 1),
                  row(
                    l10n.absenceRemark,
                    TextField(
                      controller: _remark,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: Space.s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: rowGap),
            ToneBlock(
              tone: tones.sun,
              padding: cardPadding,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: tones.sun.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.absenceWarning,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
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

  /// design/round-25: the form as a sheet over the page, its fields
  /// labelled above, the warning and the buttons under them.
  Widget _desk(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sun = context.tones.sun.strong;
    Widget field(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
    Widget box(Widget child, {VoidCallback? onTap}) => GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(7),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            child: child,
          ),
        ),
      ),
    );
    Widget choices(List<String> labels, int selected, ValueChanged<int> pick) =>
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final (i, label) in labels.indexed)
              BarChip(
                label: label,
                selected: i == selected,
                onTap: () => pick(i),
              ),
          ],
        );
    return Dialog(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outline),
      ),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.absenceNew,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              field(l10n.absenceCourse, box(Text(widget.course))),
              field(
                l10n.absenceDate,
                box(
                  onTap: _pickDate,
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_date.month}/${_date.day} '
                        '${weekdayName(context, _date.weekday)}',
                      ),
                    ],
                  ),
                ),
              ),
              field(
                l10n.absenceType,
                choices(_types(l10n), _type, (i) => setState(() => _type = i)),
              ),
              field(
                l10n.absenceMode,
                choices(
                  [l10n.absenceInPerson, l10n.absenceOnline],
                  _online ? 1 : 0,
                  (i) => setState(() => _online = i == 1),
                ),
              ),
              field(
                l10n.absenceRemark,
                box(
                  TextField(
                    controller: _remark,
                    minLines: 3,
                    maxLines: 6,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: Space.s),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 15, color: sun),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: Text(
                      l10n.absenceWarning,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sun,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: Space.s,
                children: [
                  DeskButton(
                    label: l10n.cancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                  DeskButton(
                    icon: Icons.send,
                    label: l10n.submit,
                    primary: true,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
