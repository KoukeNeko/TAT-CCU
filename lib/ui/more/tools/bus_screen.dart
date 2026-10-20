import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// The county buses the school lists on its transport page
/// (https://www.ccu.edu.tw/p/404-1000-25658.php): both stop at the
/// Activity Center. Times come from the highway bus site, opened in-app.
// shortcut: no countdown in the app; that needs TDX's bus API, which wants
// registered credentials. Add it once the app has a key.
class BusScreen extends StatelessWidget {
  const BusScreen({super.key});

  static const _live =
      'https://www.taiwanbus.tw/eBUSPage/Query/QueryResult.aspx';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tones;
    final routes = [
      ('7306', l10n.busMinxiong, 9, '73060', t.identity[2]),
      ('7309', l10n.busChiayi, 38, '73090', t.lilac),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, l10n.toolBus),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            for (final (number, route, minutes, rno, tone) in routes)
              Padding(
                padding: const EdgeInsets.only(bottom: rowGap),
                child: ToneBlock(
                  tone: tone,
                  padding: const EdgeInsets.all(18),
                  onTap: () => launchUrl(
                    Uri.parse('$_live?rno=$rno'),
                    mode: LaunchMode.inAppBrowserView,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              number,
                              style: TextStyle(
                                color: tone.ink,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              route,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${l10n.busMinutes(minutes)}・${l10n.busStop}',
                              style: TextStyle(
                                color: tone.ink.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(tone: tone, label: '${l10n.busLive} ↗'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
