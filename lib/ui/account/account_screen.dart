import 'package:clock/clock.dart' as clk;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/services/cas_credentials.dart';
import '../core/theme.dart';
import '../core/campus_web_screen.dart';
import '../core/desk_list.dart';
import '../core/desktop_mode.dart';
import '../core/widgets.dart';
import '../core/campus_systems.dart';
import '../../l10n/l10n.dart';

String _time(AppLocalizations l10n, DateTime? t) =>
    t == null ? '' : '　${l10n.verifiedAt(clock(t.hour * 60 + t.minute))}';

/// Shows the two independent sign-in states side by side.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _ecourseName;
  String? _ecourseError;
  DateTime? _ecourseCheckedAt;
  var _checking = false;
  var _casSaved = false;

  @override
  void initState() {
    super.initState();
    CasCredentials.read().then((login) {
      if (mounted) setState(() => _casSaved = login != null);
    });
  }

  Future<void> _deleteCas() async {
    await CasCredentials.delete();
    if (mounted) setState(() => _casSaved = false);
  }

  Future<void> _verifyEcourse() async {
    setState(() => _checking = true);
    try {
      _ecourseName = await context.read<EcourseAuthRepository>().verify();
      _ecourseError = null;
    } catch (e) {
      _ecourseName = null;
      _ecourseError = '$e';
    } finally {
      _ecourseCheckedAt = clk.clock.now();
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecourse = context.watch<EcourseAuthRepository>();

    final ecourseStatus = !ecourse.isSignedIn
        ? context.l10n.signedOut
        : _ecourseError != null
        ? context.l10n.verifyFailed
        : _ecourseName != null
        ? context.l10n.signedInAs(
            '$_ecourseName${_time(context.l10n, _ecourseCheckedAt)}',
          )
        : context.l10n.signedInUnverified;

    if (desktopUi(context)) return _desk(context, ecourse);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, context.l10n.account),
      body: // Builder: the list must read insets from inside this Scaffold,
          // where the glass app bar's height is part of the padding.
          Builder(
            builder: (context) => ListView(
              padding: scrollPadding(context),
              children: [
                _SessionCard(
                  tone: context.tones.lilac,
                  signedIn: ecourse.isSignedIn && _ecourseError == null,
                  title: 'eCourse2',
                  status: ecourseStatus,
                  detail: _ecourseError,
                  actions: [
                    if (!ecourse.isSignedIn)
                      FilledButton.tonal(
                        // Back to the sign-in screen.
                        onPressed: () => ecourse.setCampusOnly(false),
                        child: Text(context.l10n.signIn),
                      ),
                    if (ecourse.isSignedIn) ...[
                      FilledButton.tonal(
                        onPressed: _checking ? null : _verifyEcourse,
                        child: Text(context.l10n.verify),
                      ),
                      TextButton(
                        onPressed: () => ecourse.signOut(byUser: true),
                        child: Text(context.l10n.signOut),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _SessionCard(
                  tone: context.tones.mint,
                  // The app does not track the CAS session itself; see
                  // docs/登入狀態設計.md.
                  signedIn: null,
                  title: context.l10n.portalCas,
                  status: [
                    context.l10n.sharedWithEcourse,
                    if (_casSaved) context.l10n.autoSignIn,
                  ].join('\n'),
                  actions: [
                    FilledButton.tonal(
                      onPressed: () => openCampusPage(
                        context,
                        portalHome,
                        context.l10n.portal,
                      ),
                      child: Text(context.l10n.openPortal),
                    ),
                    if (_casSaved)
                      TextButton(
                        onPressed: _deleteCas,
                        child: Text(context.l10n.deleteSavedPassword),
                      ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  /// design/round-25 account: the two sign-ins side by side, each a box
  /// with its state and its buttons.
  Widget _desk(BuildContext context, EcourseAuthRepository ecourse) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ok = ecourse.isSignedIn && _ecourseError == null;
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    Widget box({
      required IconData icon,
      required String title,
      Widget? tag,
      required List<Widget> line,
      required List<Widget> actions,
    }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              ?tag,
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: Space.s),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(children: line),
          ),
          if (_ecourseError case final error? when title == 'eCourse2')
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: Text(error, style: muted.copyWith(color: scheme.error)),
            ),
          const SizedBox(height: Space.m),
          Wrap(spacing: Space.s, runSpacing: Space.s, children: actions),
        ],
      ),
    );

    final cards = [
      box(
        icon: Icons.menu_book_outlined,
        title: 'eCourse2',
        tag: ecourse.isSignedIn
            ? DeskTag(
                ok ? l10n.signedIn : l10n.verifyFailed,
                color: ok ? context.tones.mint.strong : scheme.error,
              )
            : null,
        line: [
          Expanded(
            child: Text(
              !ecourse.isSignedIn
                  ? l10n.signedOut
                  : _ecourseName != null && ok
                  ? l10n.signedInAs(_ecourseName!)
                  : l10n.signedInUnverified,
              style: muted,
            ),
          ),
          if (_ecourseCheckedAt case final t? when ok)
            Text(
              l10n.verifiedAt(clock(t.hour * 60 + t.minute)),
              style: muted.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
        actions: [
          if (!ecourse.isSignedIn)
            DeskButton(
              label: l10n.signIn,
              primary: true,
              onPressed: () => ecourse.setCampusOnly(false),
            )
          else ...[
            DeskButton(
              icon: Icons.check,
              label: l10n.verify,
              onPressed: _checking ? null : _verifyEcourse,
            ),
            DeskButton(
              label: l10n.signOut,
              danger: true,
              onPressed: () => ecourse.signOut(byUser: true),
            ),
          ],
        ],
      ),
      box(
        icon: Icons.lock_outline,
        title: l10n.portalCas,
        line: [
          Expanded(
            child: Text(
              [
                l10n.sharedWithEcourse,
                if (_casSaved) l10n.autoSignIn,
              ].join('・'),
              style: muted,
            ),
          ),
        ],
        actions: [
          DeskButton(
            icon: Icons.open_in_new,
            label: l10n.openPortal,
            onPressed: () => openCampusPage(context, portalHome, l10n.portal),
          ),
          if (_casSaved)
            DeskButton(
              icon: Icons.delete_outline,
              label: l10n.deleteSavedPassword,
              danger: true,
              onPressed: _deleteCas,
            ),
        ],
      ),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.account),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            Text(
              l10n.account,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Space.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.tone,
    required this.signedIn,
    required this.title,
    required this.status,
    required this.actions,
    this.detail,
  });

  final Tone tone;

  /// null when the app cannot know (the CAS session).
  final bool? signedIn;
  final String title;
  final String status;
  final String? detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToneBlock(
      tone: tone,
      radius: Corners.card,
      padding: const EdgeInsets.all(Space.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  // Buttons sit on the colored block as frosted pills.
                  FilledButtonTheme(
                    data: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 40),
                        backgroundColor: Colors.white.withValues(
                          alpha: theme.brightness == Brightness.light
                              ? 0.6
                              : 0.12,
                        ),
                        foregroundColor: tone.ink,
                        shape: const StadiumBorder(),
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    child: TextButtonTheme(
                      data: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: tone.ink,
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      child: Wrap(spacing: 8, children: actions),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: signedIn == false
                  ? tone.ink.withValues(alpha: 0.15)
                  : tone.strong,
              shape: const CookieBorder(lobes: 8, depth: 0.1),
            ),
            child: Icon(switch (signedIn) {
              true => Icons.check,
              false => Icons.remove,
              null => Icons.open_in_new,
            }, color: signedIn == false ? tone.ink : tone.fill),
          ),
        ],
      ),
    );
  }
}
