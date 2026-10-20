import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'more_screen.dart';

// shortcut: the repo is not on GitHub yet; change this once it is created.
const _repo = 'KoukeNeko/TAT-CCU';
const _contributors = ['KoukeNeko'];

// The logo's paper and shapes (design/round-11/logo-bauhaus.svg).
const _paper = Color(0xFFF1E9D8);
const _blue = Color(0xFF1D3F9A);
const _red = Color(0xFFE33B2E);
const _ink = Color(0xFF111111);

/// Design round-11 about-a-material V1: the logo's Bauhaus poster on top,
/// the app's own lists below.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tones;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status bar icons over the light poster.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // Paper behind the top half, so pulling down past the poster
            // shows more poster instead of the page background.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height / 2,
              child: const ColoredBox(color: _paper),
            ),
            ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  color: _paper,
                  height: 420 + top,
                  padding: EdgeInsets.fromLTRB(
                    Space.xxl,
                    top + Space.s,
                    Space.xxl,
                    28,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        left: -8,
                        top: 0,
                        child: RoundBackButton(
                          color: Color(0x14000000),
                          iconColor: _ink,
                        ),
                      ),
                      Positioned.fill(
                        top: 40,
                        bottom: 70,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: FutureBuilder(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, info) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TAT CCU',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (info.data case final i?)
                                Text(
                                  '${i.version}（${i.buildNumber}）',
                                  style: TextStyle(
                                    color: _ink.withValues(alpha: 0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 6,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: _red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: scrollPadding(context).copyWith(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionLabel(
                        l10n.contributors,
                        detail: '${_contributors.length}',
                      ),
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final login in _contributors)
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _blue,
                                  foregroundColor: _paper,
                                  foregroundImage: NetworkImage(
                                    'https://github.com/$login.png?size=96',
                                  ),
                                  child: Text(
                                    login[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  login,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    openExternal('https://github.com/$login'),
                              ),
                          ],
                        ),
                      ),
                      SectionLabel(l10n.project),
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            MenuRow(
                              tone: t.lilac,
                              icon: Icons.code,
                              title: 'GitHub',
                              trailing: Text(
                                _repo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              onTap: () =>
                                  openExternal('https://github.com/$_repo'),
                            ),
                            MenuRow(
                              tone: t.sun,
                              icon: Icons.palette_outlined,
                              title: l10n.designLanguage,
                              onTap: () => context.push('/more/design'),
                            ),
                            MenuRow(
                              tone: t.mint,
                              icon: Icons.description_outlined,
                              title: l10n.openSourceLicenses,
                              onTap: () => showLicensePage(
                                context: context,
                                applicationName: 'TAT CCU',
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
          ],
        ),
      ),
    );
  }
}
