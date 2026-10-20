import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/app_settings.dart';
import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/services/cas_credentials.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../more/settings_screen.dart';
import '../../l10n/l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _busy = false;

  /// eCourse2 said it is in maintenance at the last attempt.
  var _maintenance = false;

  @override
  void initState() {
    super.initState();
    // With a saved password the sign-in runs by itself; once, so backing
    // out or a failure leaves the button to the user. Not after the user
    // signed out, or it would sign straight back in.
    if (context.read<EcourseAuthRepository>().signedOutByUser) return;
    CasCredentials.read().then((login) {
      if (login != null && mounted && !_busy) _signIn();
    });
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final auth = context.read<EcourseAuthRepository>();
      // During maintenance launch.php only shows the maintenance page.
      // Unreadable settings never block signing in.
      if (await EcourseAuthRepository.siteInMaintenance() == true) {
        if (mounted) setState(() => _maintenance = true);
        return;
      }
      if (!mounted) return;
      final launch = auth.newLaunch();
      final callback = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => CampusWebScreen(
            url: launch.url.toString(),
            title: context.l10n.signInPortal,
            returnScheme: callbackScheme,
          ),
        ),
      );
      // Closed without finishing: nothing to report.
      if (callback == null) return;
      await auth.signInWithCallback(callback, launch.passport);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.signInFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Before signing in, Settings cannot be reached.
              const Align(
                alignment: Alignment.centerRight,
                child: _LanguageChip(),
              ),
              const Spacer(),
              // The four function colors as cookies: the app's mark.
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    for (final (i, t) in tones.cycle.indexed)
                      Positioned(
                        left: [0.0, 120.0, 40.0, 170.0][i],
                        top: [0.0, 20.0, 100.0, 110.0][i],
                        child: Container(
                          width: [130.0, 90.0, 100.0, 70.0][i],
                          height: [130.0, 90.0, 100.0, 70.0][i],
                          decoration: ShapeDecoration(
                            color: t.fill,
                            shape: const [
                              scallop,
                              clover,
                              spikyStar,
                              scallop,
                            ][i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('TAT CCU', style: Theme.of(context).textTheme.displaySmall),
              const Spacer(),
              // One CAS sign-in covers both: the eCourse2 launch flow signs
              // in to CAS in the shared campus WebView, which then hands the
              // token back, and campus systems reuse that CAS session.
              if (_maintenance) ...[
                Text(
                  context.l10n.ecourseMaintenance,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                // The campus systems sign in through the portal, which is
                // not down with eCourse2.
                FilledButton(
                  onPressed: () =>
                      context.read<EcourseAuthRepository>().setCampusOnly(true),
                  child: Text(context.l10n.useCampusSystems),
                ),
                const SizedBox(height: 8),
              ],
              (_maintenance ? FilledButton.tonal : FilledButton.new)(
                onPressed: _busy ? null : _signIn,
                child: Text(context.l10n.signInWithPortal),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => context.read<EcourseAuthRepository>().setDemo(true),
                child: Text(context.l10n.demoEnter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app's language, picked from the shared glass menu.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final options = languageOptions(context);
    final code = settings.locale?.languageCode;
    return BarChip(
      label: options.firstWhere((o) => o.$1 == code).$2,
      selected: false,
      dropdown: true,
      onTap: () async {
        final box = context.findRenderObject()! as RenderBox;
        // The empty string stands for following the system in the menu.
        final picked = await showGlassMenu<String>(
          context,
          anchor: box.localToGlobal(Offset.zero) & box.size,
          selected: code ?? '',
          items: [
            for (final (value, label) in options)
              (
                value: value ?? '',
                title: label,
                detail: null,
                icon: null,
                tone: null,
              ),
          ],
        );
        if (picked == null) return;
        await settings.setLocale(picked.isEmpty ? null : Locale(picked));
      },
    );
  }
}
