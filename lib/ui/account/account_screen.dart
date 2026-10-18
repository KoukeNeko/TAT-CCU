import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../core/theme.dart';
import '../core/campus_web_screen.dart';
import '../core/widgets.dart';
import '../more/portal_screen.dart';

String _time(DateTime? t) =>
    t == null ? '' : '　${t.hour}:${t.minute.toString().padLeft(2, '0')} 驗證';

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

  Future<void> _verifyEcourse() async {
    setState(() => _checking = true);
    try {
      _ecourseName = await context.read<EcourseAuthRepository>().verify();
      _ecourseError = null;
    } catch (e) {
      _ecourseName = null;
      _ecourseError = '$e';
    } finally {
      _ecourseCheckedAt = DateTime.now();
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecourse = context.watch<EcourseAuthRepository>();

    final ecourseStatus = !ecourse.isSignedIn
        ? '未登入'
        : _ecourseError != null
        ? '驗證失敗'
        : _ecourseName != null
        ? '已登入：$_ecourseName${_time(_ecourseCheckedAt)}'
        : '已登入，未驗證';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, '帳號'),
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
                    if (ecourse.isSignedIn) ...[
                      FilledButton.tonal(
                        onPressed: _checking ? null : _verifyEcourse,
                        child: const Text('驗證'),
                      ),
                      TextButton(
                        onPressed: ecourse.signOut,
                        child: const Text('登出'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _SessionCard(
                  tone: context.tones.mint,
                  // The CAS sign-in lives in the system browser, which the app
                  // cannot inspect; see docs/登入狀態設計.md.
                  signedIn: null,
                  title: '單一入口（CAS）',
                  status: '與 eCourse2 共用登入',
                  actions: [
                    FilledButton.tonal(
                      onPressed: () =>
                          openCampusPage(context, portalHome, '單一入口'),
                      child: const Text('開啟單一入口'),
                    ),
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

  /// null when the app cannot know (CAS in the system browser).
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
      radius: 32,
      padding: const EdgeInsets.all(20),
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
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    child: TextButtonTheme(
                      data: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: tone.ink,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
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
