import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/campus_cookies.dart';
import 'widgets.dart';

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
  });

  final String title, entry, host;
  final String Function() script;
  final void Function(Map<String, dynamic> json) onMessage;

  /// The page's content; null shows a progress indicator.
  final Widget? child;

  @override
  State<CampusSession> createState() => CampusSessionState();
}

class CampusSessionState extends State<CampusSession> {
  late final WebViewController _web;
  var _signingIn = false;
  var _ran = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Campus', onMessageReceived: _received)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: _arrived));
    reload();
  }

  /// Goes through the hand-off again and reruns [CampusSession.script].
  void reload() {
    _ran = false;
    _web.loadRequest(Uri.parse(widget.entry));
  }

  /// Runs another script in the signed-in page; it answers like the first.
  Future<void> run(String script) => _web.runJavaScript(script);

  void _arrived(String url) {
    final uri = Uri.parse(url);
    if (uri.host == widget.host) {
      setState(() => _signingIn = false);
      if (_ran) return;
      _ran = true;
      _web.runJavaScript(widget.script());
    } else if (uri.host == 'portal.ccu.edu.tw' &&
        uri.path == '/sso_index.php') {
      // Signing in ends on the portal home, not the system it came from.
      _web.loadRequest(Uri.parse(widget.entry));
    } else {
      // Portal or CAS sign-in form: the user fills it in (Turnstile).
      setState(() => _signingIn = true);
    }
  }

  void _received(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    // Signed in: keep this session for the next launch.
    if (json['error'] == null) CampusCookies.save();
    widget.onMessage(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: !_signingIn,
      appBar: subBar(context, _signingIn ? '登入單一入口' : widget.title),
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
            FilledButton(onPressed: onRetry, child: const Text('重試')),
          ],
        ),
      ),
    );
  }
}
