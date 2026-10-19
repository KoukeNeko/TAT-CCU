import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/campus_cookies.dart';
import 'cas_autofill.dart';
import 'widgets.dart';
import '../../l10n/l10n.dart';

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
  });

  final String title, entry, host;

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
  Timer? _stuck;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Campus', onMessageReceived: _received)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _arrived));
    _cas = CasAutofill(_web, context);
    if (widget.loadOnStart) reload();
  }

  /// Goes through the hand-off again and reruns [CampusSession.script].
  /// Completes when the script answers or the user is asked to sign in.
  Future<void> reload() {
    _ranOn = null;
    final pending = _pending ??= Completer<void>();
    _web.loadRequest(Uri.parse(widget.entry));
    return pending.future;
  }

  void _settle() {
    _pending?.complete();
    _pending = null;
  }

  /// Runs another script in the signed-in page; it answers like the first.
  Future<void> run(String script) => _web.runJavaScript(script);

  void _arrived(String url) {
    _cas.pageFinished(url);
    _stuck?.cancel();
    final uri = Uri.parse(url);
    if (widget.via.any('${uri.host}${uri.path}'.startsWith)) {
      // These pages move on by themselves; one that stays is showing the
      // user something (an error or a form), so show it.
      _stuck = Timer(const Duration(seconds: 8), () {
        if (!mounted) return;
        setState(() => _signingIn = true);
        _settle();
      });
      return;
    }
    if (uri.host == widget.host) {
      setState(() => _signingIn = false);
      // Once per page: a redirect or SAML page on the host drops the
      // script with it, so the page that replaces it runs it again.
      if (_ranOn == url) return;
      _ranOn = url;
      _web.runJavaScript(widget.script());
    } else if (uri.host == 'portal.ccu.edu.tw' &&
        uri.path == '/sso_index.php') {
      // Signing in ends on the portal home, not the system it came from.
      _web.loadRequest(Uri.parse(widget.entry));
    } else {
      // Portal or CAS sign-in form: the user fills it in (Turnstile).
      setState(() => _signingIn = true);
      _settle();
    }
  }

  void _received(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    // Signed in: keep this session for the next launch.
    if (json['error'] == null) CampusCookies.save();
    widget.onMessage(json);
    _settle();
  }

  @override
  void dispose() {
    _stuck?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: !_signingIn,
      appBar: subBar(
        context,
        _signingIn ? context.l10n.signInPortal : widget.title,
      ),
      body: Stack(
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
                  const Center(child: CircularProgressIndicator()),
            ),
        ],
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
