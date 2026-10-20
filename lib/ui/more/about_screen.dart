import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'more_screen.dart';

const _repo = 'KoukeNeko/TAT-CCU';

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
                      const _Contributors(),
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

typedef _Contributor = ({String login, String avatar, int commits});

/// Who has committed to the repo, from GitHub's public contributors list
/// (no token; 60 requests an hour per address, plenty for this page).
Future<List<_Contributor>> _fetchContributors() async {
  final r = await http.get(
    Uri.parse('https://api.github.com/repos/$_repo/contributors'),
    headers: {'accept': 'application/vnd.github+json'},
  );
  if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
  return [
    for (final c in jsonDecode(r.body) as List)
      if (c is Map && c['type'] == 'User' && c['login'] is String)
        (
          login: c['login'] as String,
          avatar: '${c['avatar_url'] ?? ''}',
          commits: (c['contributions'] as num?)?.toInt() ?? 0,
        ),
  ];
}

class _Contributors extends StatefulWidget {
  const _Contributors();

  @override
  State<_Contributors> createState() => _ContributorsState();
}

class _ContributorsState extends State<_Contributors> {
  var _load = _fetchContributors();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: _load,
      builder: (context, snap) {
        final people = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(
              l10n.contributors,
              detail: people == null ? null : '${people.length}',
            ),
            Card(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: switch (snap) {
                AsyncSnapshot(hasError: true) => ListTile(
                  title: Text(l10n.loadFailed),
                  trailing: TextButton(
                    onPressed: () =>
                        setState(() => _load = _fetchContributors()),
                    child: Text(l10n.retry),
                  ),
                ),
                _ when people == null => const Padding(
                  padding: cardPadding,
                  child: Center(child: CircularProgressIndicator()),
                ),
                _ => Column(
                  children: [
                    for (final p in people)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _blue,
                          foregroundColor: _paper,
                          foregroundImage: p.avatar.isEmpty
                              ? null
                              : NetworkImage(p.avatar),
                          child: Text(
                            p.login[0],
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        title: Text(
                          p.login,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(l10n.commitCount(p.commits)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            openExternal('https://github.com/${p.login}'),
                      ),
                  ],
                ),
              },
            ),
          ],
        );
      },
    );
  }
}
