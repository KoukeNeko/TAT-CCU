import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/cas_credentials.dart';
import '../../l10n/l10n.dart';

const _casHost = 'cas.ccu.edu.tw';

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
  const wait = setInterval(() => {
    const token = f.querySelector('[name="cf-turnstile-response"]');
    if (token && token.value) { clearInterval(wait); f.requestSubmit(); }
  }, 300);
})();
''';

/// Signs in to CAS with the saved password inside one campus WebView.
/// Call [pageFinished] from the WebView's navigation delegate.
class CasAutofill {
  CasAutofill(this._web, this._context) {
    _web.addJavaScriptChannel('CasLogin', onMessageReceived: _submitted);
  }

  final WebViewController _web;
  final BuildContext _context;
  CasLogin? _submittedLogin;

  /// One automatic try per sign-in: a wrong saved password must not be
  /// resent until CAS locks the account.
  var _tried = false;

  void _submitted(JavaScriptMessage message) {
    final json = jsonDecode(message.message) as Map<String, dynamic>;
    _submittedLogin = (
      username: '${json['username']}',
      password: '${json['password']}',
    );
  }

  Future<void> pageFinished(String url) async {
    final uri = Uri.parse(url);
    if (uri.host == _casHost) {
      if (!uri.path.startsWith('/login')) return;
      final saved = _tried ? null : await CasCredentials.read();
      if (saved != null) _tried = true;
      await _web.runJavaScript(_script(saved));
      return;
    }
    await signedIn();
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
