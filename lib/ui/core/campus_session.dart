import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/campus_cookies.dart';
import 'cas_autofill.dart';
import 'theme.dart';
import 'widgets.dart';
import '../../l10n/l10n.dart';

/// Fetches [url] inside the signed-in page and answers `{kind: 'pdf',
/// data}` with the bytes as base64, or `{kind: 'pdf', error}`.
String fetchPdfScript(String url) =>
    '''
(async () => {
  const r = await fetch(${jsonEncode(url)}, { credentials: 'same-origin' });
  const bytes = new Uint8Array(await r.arrayBuffer());
  let bin = '';
  for (let i = 0; i < bytes.length; i += 0x8000) {
    bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
  }
  Campus.postMessage(JSON.stringify({ kind: 'pdf', data: btoa(bin) }));
})().catch(e => Campus.postMessage(JSON.stringify({ kind: 'pdf', error: String(e) })));
''';

/// A campus system read in-app. A hidden WebView goes through the portal
/// hand-off at [entry]; once it lands on [host] it runs [script], which
/// reads pages same-origin and posts JSON back through `Campus.postMessage`.
/// If the portal or CAS asks to sign in, the WebView is shown instead.
///
/// The WebView shares its cookies with every other campus WebView, so one
/// sign-in covers all systems.
class CampusSession extends StatefulWidget {
  const CampusSession({
    super.key,
    required this.title,
    required this.entry,
    required this.host,
    required this.script,
    required this.onMessage,
    required this.child,
    this.loadOnStart = true,
    this.via = const [],
    this.bottom,
    this.action,
  });

  final String title, entry, host;

  /// Shown under the title once signed in, such as a search field.
  final PreferredSizeWidget? bottom;

  /// At the title's end once signed in, such as a capsule to another page.
  final Widget? action;

  /// `host/path` prefixes the hand-off passes through on its own (e.g. a
  /// SAML form that posts itself); they are not sign-in pages.
  final List<String> via;

  /// False for pages that show cached data first and load on [reload].
  final bool loadOnStart;
  final String Function() script;
  final void Function(Map<String, dynamic> json) onMessage;

  /// The page's content; null shows a progress indicator.
  final Widget? child;

  @override
  State<CampusSession> createState() => CampusSessionState();
}

class CampusSessionState extends State<CampusSession> {
  late final WebViewController _web;
  late final CasAutofill _cas;
  var _signingIn = false;
  String? _ranOn;
  Completer<void>? _pending;
  var _step = _Step.connecting;
  var _where = '';
  var _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Campus', onMessageReceived: _received)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _arrived));
    _cas = CasAutofill(
      _web,
      context,
      onVerifying: () => _go(_Step.verifying, _casHost),
    );
    if (widget.loadOnStart) reload();
  }

  /// Goes through the hand-off again and reruns [CampusSession.script].
  /// Completes when the script answers or the user is asked to sign in.
  Future<void> reload() {
    _ranOn = null;
    _go(_Step.connecting, Uri.parse(widget.entry).host);
    final pending = _pending ??= Completer<void>();
    _web.loadRequest(Uri.parse(widget.entry));
    return pending.future;
  }

  /// For pull to refresh: starts [reload] and returns at once, leaving the
  /// progress to the status capsule instead of the refresh spinner.
  Future<void> refresh() async => unawaited(reload());

  void _settle() {
    _pending?.complete();
    if (mounted) setState(() => _pending = null);
  }

  void _go(_Step step, String where) {
    if (!mounted) return;
    _slowTimer?.cancel();
    setState(() {
      _step = step;
      _where = where;
      _slow = false;
    });
    // Signing in that takes this long may be waiting on the user (a
    // Turnstile challenge, an error page), so offer to show the page.
    if (step != _Step.reading) {
      _slowTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _slow = true);
      });
    }
  }

  void _showPage() {
    _slowTimer?.cancel();
    setState(() => _signingIn = true);
    _settle();
  }

  /// Runs another script in the signed-in page; it answers like the first.
  Future<void> run(String script) => _web.runJavaScript(script);

  Future<void> _arrived(String url) async {
    final uri = Uri.parse(url);
    final signsInItself = await _cas.pageFinished(url);
    if (!mounted) return;
    if (widget.via.any('${uri.host}${uri.path}'.startsWith)) {
      _go(_Step.connecting, uri.host);
    } else if (uri.host == widget.host) {
      setState(() => _signingIn = false);
      _go(_Step.reading, uri.host);
      // Once per page: a redirect or SAML page on the host drops the
      // script with it, so the page that replaces it runs it again.
      if (_ranOn == url) return;
      _ranOn = url;
      _web.runJavaScript(widget.script());
    } else if (uri.host == 'portal.ccu.edu.tw' &&
        uri.path == '/sso_index.php') {
      // Signing in ends on the portal home, not the system it came from.
      _go(_Step.connecting, uri.host);
      _web.loadRequest(Uri.parse(widget.entry));
    } else if (signsInItself) {
      _go(uri.host == _casHost ? _Step.signingIn : _Step.connecting, uri.host);
    } else {
      // A sign-in form without a saved password, or one that failed: the
      // user fills it in.
      _showPage();
    }
  }

  void _received(JavaScriptMessage message) {
    // A script can finish after its page was closed.
    if (!mounted) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(message.message) as Map<String, dynamic>;
    } on FormatException catch (e) {
      json = {'error': 'Unreadable page reply: ${e.message}'};
    }
    // Signed in: keep this session for the next launch.
    if (json['error'] == null) CampusCookies.save();
    widget.onMessage(json);
    _settle();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: !_signingIn,
      appBar: subBar(
        context,
        _signingIn ? context.l10n.signInPortal : widget.title,
        bottom: _signingIn ? null : widget.bottom,
        action: _signingIn ? null : widget.action,
      ),
      // Builder: the capsule reads insets from inside this Scaffold, where
      // the glass app bar's height is part of the top padding.
      body: Builder(
        builder: (context) => Stack(
          children: [
            // Kept in the tree so it can load; shown only for signing in.
            Positioned.fill(
              child: Offstage(
                offstage: !_signingIn,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  child: WebViewWidget(controller: _web),
                ),
              ),
            ),
            if (!_signingIn)
              Positioned.fill(
                child:
                    widget.child ??
                    _Progress(
                      step: _step,
                      where: _where,
                      onShowPage: _slow ? _showPage : null,
                    ),
              ),
            // Refreshing a page that already shows its content.
            if (!_signingIn && widget.child != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 10,
                left: 16,
                right: 16,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, -0.4),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _pending == null
                        ? const SizedBox.shrink()
                        : _Capsule(
                            step: _step,
                            onShowPage: _slow ? _showPage : null,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _casHost = 'cas.ccu.edu.tw';

String _stepTitle(AppLocalizations l10n, _Step step) => switch (step) {
  _Step.connecting => l10n.campusConnecting,
  _Step.signingIn => l10n.signInPortal,
  _Step.verifying => l10n.campusVerifying,
  _Step.reading => l10n.campusReading,
};

/// Design S3's status capsule (design/round-11): a frosted pill under the
/// app bar while a page with content refreshes.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.step, required this.onShowPage});

  final _Step step;
  final VoidCallback? onShowPage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    const shape = StadiumBorder();
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: scheme.surface.withValues(alpha: 0.72),
            shape: StadiumBorder(
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: InkWell(
              onTap: onShowPage,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MorphingCookie(size: 26, color: context.tones.lilac.strong),
                    const SizedBox(width: 10),
                    Text(
                      '${_stepTitle(l10n, step)}'
                      '${onShowPage == null ? '' : '・${l10n.showPage}'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Step { connecting, signingIn, verifying, reading }

/// Design S2-C (design/round-11): a morphing shape in the middle, and the
/// current step in large type near the thumb with a four-part progress bar.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.step,
    required this.where,
    required this.onShowPage,
  });

  final _Step step;
  final String where;

  /// Shown once a step has taken long enough to need the user.
  final VoidCallback? onShowPage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LoadingView(
      title: _stepTitle(l10n, step),
      detail: step == _Step.signingIn ? l10n.campusFillingIn : where,
      step: step.index,
      steps: _Step.values.length,
      action: onShowPage == null
          ? null
          : FilledButton.tonal(
              onPressed: onShowPage,
              child: Text(l10n.showPage),
            ),
    );
  }
}

/// Error from a campus script with a retry button.
class CampusError extends StatelessWidget {
  const CampusError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// Footer saying when a cached campus page last read the school.
class UpdatedAt extends StatelessWidget {
  const UpdatedAt(this.time, {super.key});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        context.l10n.updatedAt(
          '${time.month}/${time.day} ${clock(time.hour * 60 + time.minute)}',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
