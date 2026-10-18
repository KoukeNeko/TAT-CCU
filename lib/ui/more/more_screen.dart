import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/repositories/ecourse_repository.dart';
import '../../data/repositories/portal_prefs.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'portal_screen.dart';

/// Design X1-B "雙登入狀態卡" (design/round-11): an account card with both
/// sign-in states, then grouped rows with favorite campus systems inline.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  /// Fetched once; the row only shows a count and skips it on failure.
  late final _grades = context.read<EcourseRepository>().gradeOverview();

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final prefs = context.watch<PortalPrefs>();
    final favorites = [for (final id in prefs.favorites) ?campusSystems[id]];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar('更多'),
      body: Builder(
        // Reads insets from inside this Scaffold, below the glass app bar.
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            const _AccountCard(),
            const SectionLabel('學業'),
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<Map<int, String>>(
                future: _grades,
                builder: (context, snap) => _Row(
                  tone: t.lilac,
                  icon: Icons.grading_outlined,
                  title: '成績',
                  detail: snap.hasData ? '${snap.data!.length} 門課' : null,
                  onTap: () => context.go('/more/grades'),
                ),
              ),
            ),
            const SectionLabel('校園'),
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _Row(
                    tone: t.peach,
                    icon: Icons.apps,
                    title: '全部校務系統',
                    onTap: () => context.go('/more/portal'),
                  ),
                  if (favorites.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        // A nested GridView otherwise pads itself by the
                        // screen's safe-area and bar insets.
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 3.4,
                        children: [
                          for (final s in favorites)
                            ToneBlock(
                              tone: t.peach,
                              radius: 16,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              onTap: () => openCampusSystem(context, prefs, s),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  s.name.replaceAll('系統', ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
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
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final tone = context.tones.lilac;
    final signedIn = context.watch<EcourseAuthRepository>().isSignedIn;
    return ToneBlock(
      tone: tone,
      radius: 28,
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/more/account'),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: ShapeDecoration(
                  color: tone.strong,
                  shape: spikyStar,
                ),
                child: Icon(Icons.check, color: tone.fill),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '帳號',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Status(
                on: signedIn,
                label: signedIn ? 'eCourse2 已登入' : 'eCourse2 未登入',
              ),
              const SizedBox(width: 6),
              // CAS lives in the system browser; the app can only say it is
              // shared with the eCourse2 sign-in.
              const _Status(on: true, label: '單一入口共用'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.on, required this.label});

  final bool on;
  final String label;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final mint = context.tones.mint;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: light ? 0.55 : 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? mint.strong : context.tones.peach.strong,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.tone,
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
  });

  final Tone tone;
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: tone.ink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detail != null)
            Text(
              detail!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}
