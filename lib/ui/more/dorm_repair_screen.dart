import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../core/floating_dock.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../../data/repositories/dorm_repair_data.dart';
import '../core/campus_systems.dart';

/// Design round-11 dorm-repair R1-A: past requests, then a full-page form
/// with the site's four fields (alpha).
class DormRepairScreen extends StatelessWidget {
  const DormRepairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final store = DormRepairStore.instance;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.drTitle,
        action: const SchoolSiteButton('0011'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final requests = store.requests;
          return PinnedActionList(
            padding: scrollPadding(context, top: 0),
            action: DockButton(
              onPressed: () => context.push('/more/dorm-repair/new'),
              tone: context.tones.lilac,
              child: Text(l10n.drRequest),
            ),
            children: [
              SectionLabel(l10n.drHistory),
              if (requests.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    l10n.drNone,
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
                      for (final (i, r) in requests.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          title: Text(
                            r.memo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${r.date.month}/${r.date.day} '
                            '${weekdayName(context, r.date.weekday)}'
                            '・${r.room}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The site's form: room and bed, email, what needs repair and whether a
/// resident must be there. Room and email can be remembered on the device.
class DormRepairFormScreen extends StatefulWidget {
  const DormRepairFormScreen({super.key});

  @override
  State<DormRepairFormScreen> createState() => _DormRepairFormScreenState();
}

class _DormRepairFormScreenState extends State<DormRepairFormScreen> {
  final _room = TextEditingController();
  final _email = TextEditingController();
  final _memo = TextEditingController();
  var _needPresence = false;
  var _remember = true;

  @override
  void initState() {
    super.initState();
    RepairContact.read().then((contact) {
      if (!mounted || contact == null) return;
      setState(() {
        _room.text = contact.room;
        _email.text = contact.email;
      });
    });
  }

  @override
  void dispose() {
    _room.dispose();
    _email.dispose();
    _memo.dispose();
    super.dispose();
  }

  String get _roomText => _room.text.trim().toUpperCase();

  bool get _valid =>
      roomPattern.hasMatch(_roomText) &&
      emailPattern.hasMatch(_email.text.trim()) &&
      _memo.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final l10n = context.l10n;
    final request = (
      date: DateTime.now(),
      room: _roomText,
      email: _email.text.trim(),
      memo: _memo.text.trim(),
      needPresence: _needPresence,
    );
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.drSubmitTitle),
        content: Text(
          '${request.room}・${request.memo}\n'
          '${request.needPresence ? l10n.drNeed : l10n.drNoNeed}・'
          '${l10n.drResultTo(request.email)}',
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
    if (yes != true || !mounted) return;
    await RepairContact.write(
      _remember ? (room: request.room, email: request.email) : null,
    );
    DormRepairStore.instance.submit(request);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final room = _roomText;
    final email = _email.text.trim();
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    InputDecoration field(String hint, String? error) => InputDecoration(
      hintText: hint,
      errorText: error,
      errorMaxLines: 2,
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: Space.s),
      counterText: '',
    );
    // The label sits above its field, as the presence choice's does.
    Widget row(String label, Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: labelStyle),
          child,
        ],
      ),
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(
        context,
        l10n.drRequest,
        action: const SchoolSiteButton('0011'),
      ),
      body: Builder(
        builder: (context) => PinnedActionList(
          padding: scrollPadding(context),
          action: DockButton(
            onPressed: _valid ? _submit : null,
            tone: context.tones.lilac,
            child: Text(l10n.submit),
          ),
          children: [
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  row(
                    l10n.drRoom,
                    TextField(
                      controller: _room,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9A-Za-z-]'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: field(
                        l10n.drRoomHint,
                        room.isEmpty || roomPattern.hasMatch(room)
                            ? null
                            : l10n.drRoomInvalid,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  row(
                    'E-mail',
                    TextField(
                      controller: _email,
                      maxLength: 50,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      onChanged: (_) => setState(() {}),
                      decoration: field(
                        l10n.drEmailHint,
                        email.isEmpty || emailPattern.hasMatch(email)
                            ? null
                            : l10n.drEmailInvalid,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  row(
                    l10n.drMemo,
                    TextField(
                      controller: _memo,
                      maxLength: 255,
                      minLines: 3,
                      maxLines: 6,
                      onChanged: (_) => setState(() {}),
                      decoration: field(
                        l10n.drMemoHint,
                        null,
                      ).copyWith(counterText: null),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.l,
                      Space.m,
                      Space.l,
                      Space.l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.drPresence, style: labelStyle),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(l10n.drNoNeed),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(l10n.drNeed),
                            ),
                          ],
                          selected: {_needPresence},
                          onSelectionChanged: (s) =>
                              setState(() => _needPresence = s.first),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _needPresence ? l10n.drNeedNote : l10n.drNoNeedNote,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: rowGap),
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                title: Text(
                  l10n.drRemember,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                value: _remember,
                onChanged: (v) => setState(() => _remember = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
