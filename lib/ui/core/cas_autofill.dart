import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/cas_credentials.dart';
import '../../l10n/l10n.dart';

/// The school's CAS sign-in host.
const casHost = 'cas.ccu.edu.tw';

/// Reports what the user submits on the CAS form and, given a saved login,
/// fills the form and submits it once Turnstile has passed on its own. The
/// Turnstile check itself is left to the widget and the user.
String _script(CasLogin? saved) =>
    '''
(() => {
  const f = document.getElementById('fm1');
  if (!f || f.dataset.tatccu) return;
  f.dataset.tatccu = '1';
  const u = f.querySelector('[name=username]'), p = f.querySelector('[name=password]');
  if (!u || !p) return;
  f.addEventListener('submit', () => CasLogin.postMessage(JSON.stringify({ username: u.value, password: p.value })), true);
  const saved = ${jsonEncode(saved == null ? null : {'username': saved.username, 'password': saved.password})};
  if (!saved) return;
  for (const [field, value] of [[u, saved.username], [p, saved.password]]) {
    field.value = value;
    field.dispatchEvent(new Event('input', { bubbles: true }));
  }
  CasLogin.postMessage(JSON.stringify({ waiting: true }));
  const wait = setInterval(() => {
    const token = f.querySelector('[name="cf-turnstile-response"]');
    if (token && token.value) { clearInterval(wait); f.requestSubmit(); }
  }, 300);
})();
''';

/// Signs in to CAS with the saved password inside one campus WebView.
/// Call [pageFinished] from the WebView's navigation delegate.
class CasAutofill {
  CasAutofill(this._web, this._context, {this.onVerifying}) {
    _web.addJavaScriptChannel('CasLogin', onMessageReceived: _submitted);
  }

  final WebViewController _web;
  final BuildContext _context;

  /// The saved password is filled in; Turnstile is still checking.
  final VoidCallback? onVerifying;
  CasLogin? _submittedLogin;

  /// One automatic try per sign-in: a wrong saved password must not be
  /// resent until CAS locks the account.
  var _tried = false;

  void _submitted(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    if (json['waiting'] == true) {
      onVerifying?.call();
      return;
    }
    _submittedLogin = (
      username: '${json['username']}',
      password: '${json['password']}',
    );
  }

  /// Once per sign-in, so a portal that sends the browser back is not
  /// sent to CAS again and again.
  var _sentToCas = false;

  /// True when this page signs in by itself (the portal home sent on to
  /// CAS, or the saved password filled in), so the WebView can stay hidden.
  Future<bool> pageFinished(String url) async {
    final uri = Uri.parse(url);
    if (uri.host == 'portal.ccu.edu.tw' &&
        (uri.path == '/' || uri.path == '/index.php') &&
        !_sentToCas) {
      // The signed-out portal home only links to its CAS sign-in.
      _sentToCas = true;
      await _web.loadRequest(
        Uri.parse('https://portal.ccu.edu.tw/login_check_cas.php'),
      );
      return true;
    }
    if (uri.host == casHost) {
      if (!uri.path.startsWith('/login')) return false;
      final saved = _tried ? null : await CasCredentials.read();
      if (saved != null) _tried = true;
      await _web.runJavaScript(_script(saved));
      return saved != null;
    }
    // Not awaited: the remember-password dialog must not hold up the page.
    unawaited(signedIn());
    return false;
  }

  /// CAS only sends the browser on after a successful sign-in; offers to
  /// remember what the user typed. Also called when the WebView is about to
  /// close on a redirect that never finishes loading a page.
  Future<void> signedIn() => _asking ??= _ask().whenComplete(() {
    _asking = null;
  });

  Future<void>? _asking;

  Future<void> _ask() async {
    final login = _submittedLogin;
    _submittedLogin = null;
    _tried = false;
    _sentToCas = false;
    if (login == null || login.username.isEmpty || login.password.isEmpty) {
      return;
    }
    if (login == await CasCredentials.read()) return;
    if (!_context.mounted) return;
    final l10n = _context.l10n;
    final remember = await showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rememberPasswordTitle),
        content: Text(l10n.rememberPasswordBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remember),
          ),
        ],
      ),
    );
    if (remember == true) await CasCredentials.save(login);
  }
}
