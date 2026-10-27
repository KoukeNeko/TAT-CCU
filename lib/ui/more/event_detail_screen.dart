import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../l10n/l10n.dart';
import '../core/floating_dock.dart';
import '../core/campus_session.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/theme.dart';
import '../core/glass_sheet.dart';
import '../core/widgets.dart';
import '../../data/services/events_data.dart';
import 'events_screen.dart';
import '../core/glass_dialog.dart';

/// An event from the list, read again signed in: whether the student has
/// signed up, the places left and the sign-up form. Signing up and
/// cancelling run in the same page, then read the event again.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.event, this.onChanged});

  final SchoolEvent event;

  /// Called after a sign-up or cancel, so the list reads again.
  final VoidCallback? onChanged;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _session = GlobalKey<CampusSessionState>();
  late var _event = widget.event;
  ({String name, String email})? _form;
  Map<String, String>? _action;

  /// False until this page has read the event signed in; acting before
  /// that would act on the list's copy.
  var _fresh = false;

  void _received(Map<String, dynamic> json) {
    final l10n = context.l10n;
    if (json['error'] != null) {
      _action = null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${json['error']}')));
      return;
    }
    final event = eventOf((json['event'] as Map).cast<String, dynamic>());
    final form = json['form'] as Map?;
    final result = json['result'] as Map?;
    _action = null;
    setState(() {
      _event = event;
      _fresh = true;
      _form = form == null
          ? null
          : (name: '${form['name'] ?? ''}', email: '${form['email'] ?? ''}');
    });
    if (result == null) return;
    // Success shows in the page itself: the pill and the button change.
    final ok = result['kind'] == 'signUp' ? event.signedUp : !event.signedUp;
    if (ok) {
      widget.onChanged?.call();
      return;
    }
    final message = [
      result['kind'] == 'signUp' ? l10n.signUpFailed : l10n.cancelSignUpFailed,
      '${result['message'] ?? ''}'.trim(),
    ].where((s) => s.isNotEmpty).join('：');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _act(Map<String, String> action) {
    setState(() => _fresh = false);
    _action = action;
    _session.currentState?.refresh();
  }

  Future<void> _signUp() async {
    final form = _form;
    if (form == null) return;
    final email = await showGlassSheet<String>(
      context,
      builder: (context) => _SignUpSheet(event: _event, form: form),
    );
    if (email != null) _act({'signUp': email});
  }

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final cancel = _event.cancel;
    if (cancel == null) return;
    final yes = await showGlassDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: l10n.cancelSignUpTitle,
        content: Text(_event.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepSignUp),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelSignUp),
          ),
        ],
      ),
    );
    if (yes == true) _act({'cancel': cancel});
  }

  @override
  Widget build(BuildContext context) {
    return CampusSession(
      key: _session,
      title: context.l10n.events,
      entry: eventsEntry('/event/detail/list/${_event.id}/'),
      host: eventsHost,
      script: () => readEvent(_event.id, _action),
      // The demo account keeps the public details from the list.
      loadOnStart: !context.read<EcourseAuthRepository>().isDemo,
      onMessage: _received,
      child: Builder(
        // Reads insets from inside the session's Scaffold.
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: PullRefresh(
                onRefresh: () async => _session.currentState?.refresh(),
                child: _body(context),
              ),
            ),
            if (!desktopUi(context))
              Positioned(left: 0, right: 0, bottom: 0, child: _dock(context)),
          ],
        ),
      ),
    );
  }

  Widget _dock(BuildContext context) {
    final (label, onPressed, tone) = _signUpAction(context);
    return DockButton(onPressed: onPressed, tone: tone, child: Text(label));
  }

  /// What the page's one button does for the event's status.
  (String, VoidCallback?, Tone?) _signUpAction(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final e = _event;
    return switch (statusOf(e, clk.clock.now())) {
      EventStatus.open => (
        l10n.signUp,
        _fresh && _form != null ? _signUp : null,
        tones.lilac,
      ),
      EventStatus.waitlist => (
        l10n.signUpWaitlist,
        _fresh && _form != null ? _signUp : null,
        tones.sun,
      ),
      EventStatus.mine => (
        l10n.cancelSignUp,
        _fresh ? _cancel : null,
        tones.peach,
      ),
      EventStatus.external => (
        '${l10n.goSignUp} ↗',
        () => openExternal(e.link!),
        tones.peach,
      ),
      EventStatus.full => (l10n.eventFull, null, null),
      EventStatus.closed => (l10n.signUpClosed, null, null),
    };
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final e = _event;
    final now = clk.clock.now();
    final status = statusOf(e, now);
    final tone = switch (status) {
      EventStatus.open => tones.mint,
      EventStatus.waitlist => tones.sun,
      EventStatus.mine => tones.lilac,
      EventStatus.external => tones.peach,
      EventStatus.full || EventStatus.closed => Tone(
        scheme.surfaceContainerHigh,
        scheme.onSurface,
        scheme.onSurfaceVariant,
      ),
    };
    final top = MediaQuery.paddingOf(context).top;
    final spots = e.spots;
    final waitlist = e.waitlist;
    final quota = switch (status) {
      EventStatus.waitlist when waitlist != null => (
        l10n.waitlistOnly(waitlist.taken, waitlist.total),
        waitlist.taken / waitlist.total,
      ),
      EventStatus.open || EventStatus.mine when spots != null => (
        '${spots.taken} / ${spots.total}',
        spots.taken / spots.total,
      ),
      _ => null,
    };
    final start = e.start;
    final end = e.end;
    String when() {
      if (start == null) return '';
      final sameDay =
          end == null ||
          (end.year == start.year &&
              end.month == start.month &&
              end.day == start.day);
      return sameDay
          ? '${dateTimeLabel(context, start)}'
                '${end == null ? '' : '–${clock(end.hour * 60 + end.minute)}'}'
          : '${dateTimeLabel(context, start)} – ${dateTimeLabel(context, end)}';
    }

    if (desktopUi(context)) {
      return _desk(context, when(), quota?.$1);
    }
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(pageMargin, 0, pageMargin, Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (e.category.isNotEmpty)
                StatusPill(tone: tone, label: e.category),
              if (e.signedUp)
                StatusPill(tone: tones.lilac, label: l10n.signedUp),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            e.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          if (quota case (final text, final ratio)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1).toDouble(),
                      minHeight: 8,
                      color: tone.strong,
                      backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.paddingOf(context).bottom + FloatingDock.clearance + 16,
      ),
      children: [
        if (e.image case final url?)
          // The poster's blurred backdrop fades into the page; the title
          // sits on the fade, below the poster itself.
          Stack(
            children: [
              SizedBox(
                height: top + 300,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.push('/more/events/poster', extra: url),
                      child: EventPoster(
                        url: url,
                        padding: EdgeInsets.fromLTRB(0, top + Space.s, 0, 100),
                        fadeOut: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: top + 212),
                child: title,
              ),
            ],
          )
        else
          Padding(
            padding: EdgeInsets.only(top: top + pageTop),
            child: title,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            pageMargin,
            Space.m,
            pageMargin,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: scheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, (label, value)) in [
                      (l10n.eventDate, when()),
                      (l10n.eventPlace, e.place),
                      (l10n.eventCategory, e.category),
                      (l10n.eventOrganizer, e.organizer),
                      (l10n.eventContact, e.contact),
                    ].where((r) => r.$2.isNotEmpty).indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.l,
                          vertical: Space.m,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (e.intro.isNotEmpty) ...[
                SectionLabel(l10n.eventIntro),
                Card(
                  color: scheme.surfaceContainerLow,
                  child: Padding(
                    padding: cardPadding,
                    child: SelectableText(
                      e.intro,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// design/round-25 event-detail: the poster as a banner, the title with
  /// its state, the facts as label and value, the introduction, and the
  /// sign-up button below.
  Widget _desk(BuildContext context, String when, String? quota) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final e = _event;
    final (pillTone, pill) = eventPill(context, e, clk.clock.now());
    final (label, onPressed, _) = _signUpAction(context);
    return ListView(
      padding: scrollPadding(context),
      children: [
        if (e.image case final url?) ...[
          GestureDetector(
            onTap: () => context.push('/more/events/poster', extra: url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: 150, child: EventPoster(url: url)),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SelectableText(
              e.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            DeskTag(pill, color: pillTone.strong),
          ],
        ),
        const SizedBox(height: 14),
        for (final (label, value) in [
          (l10n.eventDate, when),
          (l10n.eventPlace, e.place),
          (l10n.eventCategory, e.category),
          (l10n.eventOrganizer, e.organizer),
          (l10n.eventContact, e.contact),
        ].where((r) => r.$2.isNotEmpty))
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 106,
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w700, color: muted),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        if (e.intro.isNotEmpty) ...[
          SectionLabel(l10n.eventIntro, detail: quota),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 34 * 13),
              child: SelectableText(
                e.intro,
                style: TextStyle(
                  height: 1.75,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: DeskButton(
            label: label,
            primary: !e.signedUp && onPressed != null,
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}

/// Name as the site has it; the email can be changed for this sign-up.
class _SignUpSheet extends StatefulWidget {
  const _SignUpSheet({required this.event, required this.form});

  final SchoolEvent event;
  final ({String name, String email}) form;

  @override
  State<_SignUpSheet> createState() => _SignUpSheetState();
}

class _SignUpSheetState extends State<_SignUpSheet> {
  late final _email = TextEditingController(text: widget.form.email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final valid = RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim());
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EventThumb(event: widget.event, width: 80, height: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.signUp,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.form.name.isNotEmpty)
            InputDecorator(
              decoration: InputDecoration(labelText: l10n.signUpName),
              child: Text(
                widget.form.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.signUpEmail),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: valid
                  ? () => Navigator.pop(context, _email.text.trim())
                  : null,
              child: Text(l10n.submit),
            ),
          ),
        ],
      ),
    );
  }
}

/// A poster on black, to read its small print; pinch to zoom.
class PosterScreen extends StatelessWidget {
  const PosterScreen({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            child: RoundBackButton(
              color: Colors.white.withValues(alpha: 0.16),
              iconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
