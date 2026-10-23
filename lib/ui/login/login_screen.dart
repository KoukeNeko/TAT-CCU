import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/app_settings.dart';
import '../../data/repositories/ecourse_auth_repository.dart';
import '../../data/services/cas_credentials.dart';
import '../core/app_shell.dart';
import '../core/campus_web_screen.dart';
import '../core/glass.dart';
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

  /// Login design F (design/round-13/login): the shapes behind frosted
  /// glass, and the language picked on a bar like the nav bar.
  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // A phone's width on a tablet or a desktop window.
            constraints: const BoxConstraints(maxWidth: 440),
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth, h = box.maxHeight;
                Widget cookie(Tone tone, ShapeBorder shape, double size) =>
                    Container(
                      width: size * w,
                      height: size * w,
                      decoration: ShapeDecoration(
                        color: tone.fill,
                        shape: shape,
                      ),
                    );
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // The four function colors as cookies: the app's mark.
                    Positioned(
                      left: -0.15 * w,
                      top: 0.33 * h,
                      child: cookie(tones.lilac, scallop, 0.77),
                    ),
                    Positioned(
                      right: -0.08 * w,
                      top: 0.27 * h,
                      child: cookie(tones.mint, clover, 0.46),
                    ),
                    Positioned(
                      right: 0.1 * w,
                      top: 0.48 * h,
                      child: cookie(tones.peach, spikyStar, 0.46),
                    ),
                    Positioned(
                      left: 0.38 * w,
                      top: 0.6 * h,
                      child: cookie(tones.sun, scallop, 0.26),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.xl,
                        Space.xxl * 2,
                        Space.xl,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TAT CCU', style: text.displaySmall),
                          const SizedBox(height: Space.xs),
                          Text(
                            context.l10n.appTagline,
                            style: text.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: Space.m,
                      right: Space.m,
                      bottom: Space.m,
                      child: GlassSurface(
                        radius: BorderRadius.circular(40),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.l,
                            Space.l,
                            Space.l,
                            Space.s,
                          ),
                          child: _actions(context),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Before signing in, Settings cannot be reached.
      const _LanguageBar(),
      const SizedBox(height: Space.l),
      // One CAS sign-in covers both: the eCourse2 launch flow signs in to
      // CAS in the shared campus WebView, which then hands the token back,
      // and campus systems reuse that CAS session.
      if (_maintenance) ...[
        Text(
          context.l10n.ecourseMaintenance,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        // The campus systems sign in through the portal, which is not down
        // with eCourse2.
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
      const SizedBox(height: 4),
      TextButton(
        onPressed: _busy
            ? null
            : () => context.read<EcourseAuthRepository>().setDemo(true),
        child: Text(context.l10n.demoEnter),
      ),
    ],
  );
}

/// The app's language on a bar that behaves like the nav bar: the one in
/// use widens into a capsule with the lilac cookie; pressing lifts the bar,
/// and dragging across moves the capsule with a tick at each language.
class _LanguageBar extends StatefulWidget {
  const _LanguageBar();

  @override
  State<_LanguageBar> createState() => _LanguageBarState();
}

class _LanguageBarState extends State<_LanguageBar> {
  /// Where the finger went down; null when nothing is touching.
  double? _down;

  /// Language the capsule follows while dragging; null for a plain press.
  int? _hover;

  static const _wide = 1.6;

  /// Slot widths with [selected] widened into the capsule.
  List<double> _slots(double width, int count, int selected) {
    final unit = width / (count - 1 + _wide);
    return [
      for (var i = 0; i < count; i++) i == selected ? unit * _wide : unit,
    ];
  }

  /// Slot under [x], laid out for the language shown so the widened capsule
  /// stays under the finger.
  int _indexAt(double x, List<double> slots) {
    var edge = 0.0;
    for (final (i, w) in slots.indexed) {
      edge += w;
      if (x < edge) return i;
    }
    return slots.length - 1;
  }

  void _slide(double x, int current, List<double> slots) {
    final down = _down;
    if (down == null) return;
    if (_hover == null && (x - down).abs() < barDragSlop) return;
    final i = _indexAt(x, slots);
    if (i == _hover) return;
    if (_hover != null || i != current) HapticFeedback.selectionClick();
    setState(() => _hover = i);
  }

  void _release(
    List<double> slots,
    int current,
    void Function(int) pick, {
    required bool commit,
  }) {
    final down = _down;
    final target = _hover ?? (down == null ? null : _indexAt(down, slots));
    setState(() {
      _down = null;
      _hover = null;
    });
    if (!commit || target == null || target == current) return;
    HapticFeedback.selectionClick();
    pick(target);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final scheme = Theme.of(context).colorScheme;
    final lilac = context.tones.lilac;
    final code =
        settings.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    // Following the system stays in Settings; here the language is picked.
    final options = [
      for (final (code, label) in languageOptions(context))
        if (code != null) (code, label),
    ];
    final current = options.indexWhere((o) => o.$1 == code);
    final shown = _hover ?? current;
    final pressed = _down != null;
    return AnimatedScale(
      // Press: the bar lifts slightly; release springs back.
      scale: pressed ? 1.02 : 1,
      duration: barMove,
      curve: barSettle,
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: ShapeDecoration(
          color: Colors.black.withValues(alpha: pressed ? 0.38 : 0.3),
          shape: const StadiumBorder(),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final slots = _slots(box.maxWidth, options.length, shown);
            void pick(int i) => settings.setLocale(Locale(options[i].$1));
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => setState(() => _down = e.localPosition.dx),
              onPointerMove: (e) => _slide(e.localPosition.dx, current, slots),
              onPointerUp: (_) => _release(slots, current, pick, commit: true),
              onPointerCancel: (_) =>
                  _release(slots, current, pick, commit: false),
              child: Row(
                children: [
                  for (final (i, (_, label)) in options.indexed)
                    _tab(
                      label: label,
                      width: slots[i],
                      selected: i == shown,
                      pressed: pressed && i == shown,
                      scheme: scheme,
                      cookie: lilac.fill,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tab({
    required String label,
    required double width,
    required bool selected,
    required bool pressed,
    required ColorScheme scheme,
    required Color cookie,
  }) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: AnimatedContainer(
      duration: barMove,
      // No overshoot: the slot widths must always sum to the bar.
      curve: barSettle,
      width: width,
      height: 48,
      decoration: ShapeDecoration(
        // Pressing deepens the capsule so the finger has something to hold.
        color: selected
            ? Color.lerp(scheme.primary, cookie, pressed ? 0.18 : 0)
            : Colors.transparent,
        shape: const StadiumBorder(),
      ),
      child: AnimatedScale(
        scale: pressed ? 1.03 : 1,
        duration: barMove,
        curve: barSettle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRect(
              child: AnimatedSize(
                duration: barMove,
                curve: barSettle,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: Space.s),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: ShapeDecoration(
                            color: cookie,
                            shape: scallop,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: barMove,
                curve: barSettle,
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
