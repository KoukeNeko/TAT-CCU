import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../core/campus_session.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'events_data.dart';
import 'events_screen.dart';

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
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SignUpSheet(event: _event, form: form),
    );
    if (email != null) _act({'signUp': email});
  }

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final cancel = _event.cancel;
    if (cancel == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelSignUpTitle),
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
      onMessage: _received,
      child: Builder(
        // Reads insets from inside the session's Scaffold.
        builder: (context) => Stack(
          children: [
            Positioned.fill(child: _body(context)),
            Positioned(
              left: pageMargin,
              right: pageMargin,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: _button(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final e = _event;
    final (label, onPressed, fill, ink) = switch (statusOf(e, DateTime.now())) {
      EventStatus.open => (
        l10n.signUp,
        _fresh && _form != null ? _signUp : null,
        tones.lilac.strong,
        tones.lilac.fill,
      ),
      EventStatus.waitlist => (
        l10n.signUpWaitlist,
        _fresh && _form != null ? _signUp : null,
        tones.sun.strong,
        tones.sun.fill,
      ),
      EventStatus.mine => (
        l10n.cancelSignUp,
        _fresh ? _cancel : null,
        scheme.surfaceContainerLow,
        tones.peach.strong,
      ),
      EventStatus.external => (
        '${l10n.goSignUp} ↗',
        () => openExternal(e.link!),
        tones.peach.strong,
        tones.peach.fill,
      ),
      EventStatus.full => (l10n.eventFull, null, null, null),
      EventStatus.closed => (l10n.signUpClosed, null, null, null),
    };
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: fill ?? scheme.surfaceContainerHigh,
          foregroundColor: ink ?? scheme.onSurfaceVariant,
          disabledBackgroundColor: fill == null
              ? scheme.surfaceContainerHigh
              : fill.withValues(alpha: 0.5),
          disabledForegroundColor: ink == null
              ? scheme.onSurfaceVariant
              : ink.withValues(alpha: 0.7),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          side: e.signedUp ? BorderSide(color: scheme.outlineVariant) : null,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final e = _event;
    final now = DateTime.now();
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

    final title = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: e.image == null
            ? const BorderRadius.vertical(bottom: Radius.circular(Corners.card))
            : const BorderRadius.vertical(top: Radius.circular(Corners.card)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: tone.ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.category.isNotEmpty)
              StatusPill(
                tone: Tone(
                  Colors.white.withValues(alpha: light ? 0.6 : 0.12),
                  tone.ink,
                  tone.ink,
                ),
                label: e.category,
              ),
            const SizedBox(height: 8),
            Text(
              e.title,
              style: const TextStyle(
                fontSize: 20,
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
                        color: tone.ink,
                        backgroundColor: tone.ink.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (e.signedUp) ...[
              const SizedBox(height: 10),
              StatusPill(
                tone: Tone(
                  Colors.white.withValues(alpha: light ? 0.6 : 0.12),
                  tone.ink,
                  tone.ink,
                ),
                label: l10n.signedUp,
              ),
            ],
          ],
        ),
      ),
    );

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 90,
      ),
      children: [
        if (e.image case final url?)
          // The poster sits between the app bar and the title, which
          // overlaps its last 26 px.
          Stack(
            children: [
              GestureDetector(
                onTap: () => context.push('/more/events/poster', extra: url),
                child: SizedBox(
                  height: top + 236 - 26,
                  width: double.infinity,
                  child: EventPoster(
                    url: url,
                    padding: EdgeInsets.fromLTRB(0, top + 8, 0, 12),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: top + 236 - 26),
                child: title,
              ),
            ],
          )
        else
          Padding(
            padding: EdgeInsets.only(top: top),
            child: title,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(pageMargin, 10, pageMargin, 0),
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
                          horizontal: 14,
                          vertical: 12,
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
                    padding: const EdgeInsets.all(14),
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
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
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
              decoration: InputDecoration(
                labelText: l10n.signUpName,
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
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
            decoration: InputDecoration(
              labelText: l10n.signUpEmail,
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
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
