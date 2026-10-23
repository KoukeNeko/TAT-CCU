import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_repository.dart';
import '../../data/services/ecourse_web.dart';
import '../../data/services/html_text.dart';
import '../../l10n/l10n.dart';
import '../core/campus_session.dart';
import '../core/glass_sheet.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'notifications_screen.dart';

typedef _Person = ({int id, String name, bool staff});

/// Writes eCourse2 mail in the app (design/round-11 mail-envelope-variants
/// B2): the letter above, the envelope with course, recipients and 送出
/// docked above the keyboard. Sending runs [sendMail] in a signed-in
/// eCourse2 page behind the fields, so nothing exists on eCourse2 until
/// 送出. A reply ([replyTo]) keeps the recipient and subject eCourse2
/// fills in.
class MailComposeScreen extends StatefulWidget {
  const MailComposeScreen({super.key, this.replyTo, this.replyName});

  final int? replyTo;
  final String? replyName;

  @override
  State<MailComposeScreen> createState() => _MailComposeScreenState();
}

class _MailComposeScreenState extends State<MailComposeScreen>
    with SingleTickerProviderStateMixin {
  final _session = GlobalKey<CampusSessionState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();

  /// The send animation: the letter sinks into the envelope, the envelope
  /// shoots up, then the 已寄出 badge.
  late final _sent = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// The signed-in page has answered and can send.
  var _ready = false;
  var _sending = false;
  Timer? _timeout;

  final _coursePill = GlobalKey();
  late final _courses = context.read<EcourseRepository>().mailCourses();
  ({int id, String name})? _course;
  Future<List<_Person>>? _people;
  final _to = <int, String>{};

  bool get _reply => widget.replyTo != null;

  bool get _canSend =>
      _ready &&
      !_sending &&
      _body.text.trim().isNotEmpty &&
      (_reply || _to.isNotEmpty && _subject.text.trim().isNotEmpty);

  @override
  void dispose() {
    _timeout?.cancel();
    _sent.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _received(Map<String, dynamic> message) async {
    switch (message) {
      case {'kind': 'ready'}:
        setState(() => _ready = true);
      case {'kind': 'sent', 'ok': true}:
        _timeout?.cancel();
        FocusScope.of(context).unfocus();
        if (!MediaQuery.disableAnimationsOf(context)) {
          await _sent.forward();
        }
        if (mounted) Navigator.of(context).pop(true);
      default:
        _timeout?.cancel();
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message['error'] ?? context.l10n.sendFailed}'),
          ),
        );
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await _session.currentState?.run(
      sendMail(
        courseId: _course?.id,
        to: _to.keys.toList(),
        replyTo: widget.replyTo,
        subject: _subject.text.trim(),
        html: textAsHtml(_body.text.trim()),
      ),
    );
    // An expired session may never answer; let the button work again. The
    // letter may still have gone out, so this does not say it failed.
    _timeout = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_sending) return;
      setState(() => _sending = false);
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sendUnconfirmed),
          action: SnackBarAction(
            label: l10n.viewSentMail,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SentMailScreen()),
            ),
          ),
        ),
      );
    });
  }

  /// The shared glass menu, dropped from the course pill.
  Future<void> _pickCourse() async {
    final courses = await _courses;
    final pill = _coursePill.currentContext;
    if (!mounted || pill == null || !pill.mounted) return;
    final box = pill.findRenderObject()! as RenderBox;
    final id = await showGlassMenu<int>(
      pill,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      selected: _course?.id,
      items: [
        for (final c in courses)
          (value: c.id, title: c.name, detail: null, icon: null, tone: null),
      ],
    );
    final picked = courses.where((c) => c.id == id).firstOrNull;
    if (picked == null) return;
    if (picked.id == _course?.id || !mounted) return;
    setState(() {
      _course = (id: picked.id, name: picked.name);
      _to.clear();
      _people = context.read<EcourseRepository>().participants(picked.id);
    });
  }

  Future<void> _pickPeople() async {
    if (_course == null) return _pickCourse();
    await showGlassSheet<void>(
      context,
      tall: true,
      title: context.l10n.addRecipient,
      action: Builder(
        builder: (sheet) => FilledButton(
          onPressed: () => Navigator.pop(sheet),
          child: Text(context.l10n.done),
        ),
      ),
      builder: (context) => _PeopleSheet(
        people: _people!,
        chosen: _to,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final lilac = context.tones.lilac;
    // No box and no bar: the paper card is the field.
    InputDecoration bare(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      filled: false,
      isCollapsed: true,
      // The theme's field padding would add to the card's own 16.
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    );
    return CampusSession(
      key: _session,
      title: _reply ? l10n.reply : l10n.compose,
      entry: ecourseEntry,
      host: ecourseHost,
      script: () => ecourseScript("post({ kind: 'ready' });"),
      onMessage: _received,
      action: FilledButton(
        onPressed: _canSend ? _send : null,
        child: _sending
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(l10n.submit),
      ),
      // Builder: insets have to come from inside the session's Scaffold,
      // where the glass app bar is part of the top padding.
      child: Builder(
        builder: (context) => AnimatedBuilder(
          animation: _sent,
          builder: (context, child) {
            final t = _sent.value;
            final fly = Curves.easeInBack.transform((t / 0.55).clamp(0.0, 1.0));
            final badge = Curves.elasticOut.transform(
              ((t - 0.5) / 0.5).clamp(0.0, 1.0),
            );
            return Stack(
              children: [
                // The letter lifts away, smaller, as it goes.
                Opacity(
                  opacity: (1 - fly).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -600 * fly),
                    child: Transform.scale(scale: 1 - 0.4 * fly, child: child),
                  ),
                ),
                if (badge > 0)
                  Center(
                    child: Transform.scale(
                      scale: badge,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: ShapeDecoration(
                              color: context.tones.mint.strong,
                              shape: spikyStar,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 52,
                              color: context.tones.mint.fill,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.mailSent,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          // Design round-11 compose-v3-variants C3: the course as a pill,
          // the recipients as chips, subject and body on one paper card.
          child: ListView(
            padding: scrollPadding(context),
            children: [
              if (!_reply)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    key: _coursePill,
                    color: scheme.surfaceContainerLow,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _sending ? null : _pickCourse,
                      // 44: Apple's minimum touch target. Center with
                      // widthFactor so the pill hugs the course name.
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.l,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '${_course?.name ?? l10n.courseSection} ▾',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _course == null
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: Space.m, bottom: Space.m),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_reply)
                      _Recipient(name: widget.replyName ?? '')
                    else ...[
                      for (final MapEntry(key: id, value: name) in _to.entries)
                        _Recipient(
                          name: name,
                          onRemove: _sending
                              ? null
                              : () => setState(() => _to.remove(id)),
                        ),
                      Semantics(
                        button: true,
                        label: l10n.addRecipient,
                        child: Material(
                          color: lilac.fill,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _sending ? null : _pickPeople,
                            child: SizedBox.square(
                              dimension: 44,
                              child: Icon(
                                Icons.add,
                                size: 22,
                                color: lilac.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                // 24 as drawn in the mockup, not the theme's 28.
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_reply)
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.l,
                        ),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: scheme.outlineVariant),
                          ),
                        ),
                        child: TextField(
                          controller: _subject,
                          enabled: !_sending,
                          onChanged: (_) => setState(() {}),
                          decoration: bare(l10n.subject),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.l,
                        Space.l,
                        Space.l,
                        Space.l,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 170),
                        child: TextField(
                          controller: _body,
                          enabled: !_sending,
                          autofocus: _reply,
                          onChanged: (_) => setState(() {}),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: bare(l10n.messageBody),
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A recipient chip: initial, name, and × when it can be removed.
class _Recipient extends StatelessWidget {
  const _Recipient({required this.name, this.onRemove});

  final String name;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lilac = context.tones.lilac;
    return Container(
      height: 44,
      padding: EdgeInsets.only(
        left: Space.s,
        right: onRemove == null ? Space.l : 0,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: lilac.fill,
            foregroundColor: lilac.ink,
            child: Text(
              name.characters.firstOrNull ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: onRemove,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Everyone in the course to tick, teachers and TAs first; the search
/// narrows both lists by name or student number (part of eCourse2's name).
class _PeopleSheet extends StatefulWidget {
  const _PeopleSheet({
    required this.people,
    required this.chosen,
    required this.onChanged,
  });

  final Future<List<_Person>> people;
  final Map<int, String> chosen;
  final VoidCallback onChanged;

  @override
  State<_PeopleSheet> createState() => _PeopleSheetState();
}

class _PeopleSheetState extends State<_PeopleSheet> {
  var _query = '';

  void _toggle(_Person p) {
    setState(() {
      if (widget.chosen.remove(p.id) == null) widget.chosen[p.id] = p.name;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: widget.people,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(l10n.loadFailed));
        final people = snap.data;
        if (people == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // Spaces ignored: Moodle may put one between family and given name.
        String plain(String s) => s.replaceAll(RegExp(r'\s'), '').toLowerCase();
        final q = plain(_query);
        final shown = [
          for (final p in people)
            if (plain(p.name).contains(q)) p,
        ];
        Widget row(_Person p) => CheckboxListTile(
          value: widget.chosen.containsKey(p.id),
          onChanged: (_) => _toggle(p),
          title: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: Space.s),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s),
              child: TextField(
                onChanged: (q) => setState(() => _query = q.trim()),
                decoration: InputDecoration(
                  hintText: l10n.searchPeople,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            for (final (label, staff) in [
              (l10n.staff, true),
              (l10n.others, false),
            ])
              if (shown.any((p) => p.staff == staff)) ...[
                SectionLabel(label),
                for (final p in shown)
                  if (p.staff == staff) row(p),
              ],
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(child: Text(l10n.noMatchingPeople)),
              ),
          ],
        );
      },
    );
  }
}
