import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/campus_cache.dart';
import '../../l10n/l10n.dart';
import '../core/campus_session.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../data/services/ecourse_web.dart';

/// 請假單 (design/round-11 course-modules-screens), shaped like 宿舍維修:
/// the student's own requests, then a button to the full-page form.
class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key, required this.cmid, this.title});

  final int cmid;
  final String? title;

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  final _session = GlobalKey<CampusSessionState>();
  late final _cacheKey = 'absences-${widget.cmid}';
  Map<String, dynamic>? _json;
  DateTime? _savedAt;
  String? _error;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    CampusCache.read(_cacheKey).then((cached) {
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _json = cached.json;
          _savedAt = cached.savedAt;
        });
      }
      _session.currentState?.reload();
    });
  }

  Future<void> _received(Map<String, dynamic> json) async {
    if (json['kind'] == 'submitted') {
      setState(() => _sending = false);
      if (json['ok'] == true) {
        await _session.currentState?.reload();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${json['error'] ?? context.l10n.loadFailed}'),
          ),
        );
      }
      return;
    }
    if (json['error'] != null) {
      setState(() {
        _error = '${json['error']}';
        _sending = false;
      });
      return;
    }
    final savedAt = await CampusCache.write(_cacheKey, json);
    if (!mounted) return;
    setState(() {
      _error = null;
      _json = json;
      _savedAt = savedAt;
    });
  }

  Future<void> _new() async {
    final request = await Navigator.of(context).push<AbsenceRequest>(
      MaterialPageRoute(
        builder: (_) => AbsenceFormScreen(course: '${_json?['course'] ?? ''}'),
      ),
    );
    if (request == null || !mounted) return;
    setState(() => _sending = true);
    await _session.currentState?.run(submitAbsence(widget.cmid, request));
    // An expired session may never answer; let the button work again.
    Timer(const Duration(seconds: 30), () {
      if (!mounted || !_sending) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.loadFailed)));
    });
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _session.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final json = _json;
    return CampusSession(
      key: _session,
      title: widget.title ?? '',
      entry: ecourseEntry,
      host: ecourseHost,
      loadOnStart: false,
      script: () => readAbsences(widget.cmid),
      onMessage: _received,
      child: _error != null
          ? CampusError(message: _error!, onRetry: _reload)
          : json == null
          ? null
          : Builder(builder: (context) => _body(context, json)),
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
    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            edgeOffset: MediaQuery.paddingOf(context).top,
            onRefresh: () async => _session.currentState?.refresh(),
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
                if (_savedAt case final time?) UpdatedAt(time),
              ],
            ),
          ),
        ),
        Positioned(
          left: pageMargin,
          right: pageMargin,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _sending ? null : _new,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(l10n.absenceNew),
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
  var _date = DateUtils.dateOnly(DateTime.now());
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
    final now = DateTime.now();
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
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.absenceSubmitTitle),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.absenceNew),
      body: Builder(
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: scrollPadding(
                  context,
                ).copyWith(bottom: MediaQuery.paddingOf(context).bottom + 90),
                children: [
                  Card(
                    color: scheme.surfaceContainerLow,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        row(
                          l10n.absenceCourse,
                          Text(widget.course, style: value),
                        ),
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
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(l10n.absenceInPerson),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(l10n.absenceOnline),
                              ),
                            ],
                            selected: {_online},
                            onSelectionChanged: (s) =>
                                setState(() => _online = s.first),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: rowGap),
                  ToneBlock(
                    tone: tones.sun,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: tones.sun.ink,
                        ),
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
            Positioned(
              left: pageMargin,
              right: pageMargin,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.submit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
