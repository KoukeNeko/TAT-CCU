import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../l10n/l10n.dart';
import 'campus_web_view.dart';
import 'cas_autofill.dart';
import 'widgets.dart';

/// Opens a campus system inside the app. Every campus page uses this one
/// kind of WebView: they share the default cookie store, so the portal and
/// CAS sign-in made in any of them carries to the rest, and to the iCCU
/// loader, while the app runs. It covers the nav bar: the school's pages
/// bring their own navigation and need the whole height.
///
/// The demo account has no school sign-in, so it gets a note instead.
Future<void> openCampusPage(
  BuildContext context,
  String url,
  String title, {
  Map<String, String>? form,
}) async {
  if (context.read<EcourseAuthRepository>().isDemo) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.demoUnavailable)));
    return;
  }
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => CampusWebScreen(url: url, title: title, form: form),
    ),
  );
}

class CampusWebScreen extends StatefulWidget {
  const CampusWebScreen({
    super.key,
    required this.url,
    required this.title,
    this.returnScheme,
    this.form,
  });

  final String url, title;

  /// Posted to [url] as a form, for a page reached by a form button.
  final Map<String, String>? form;

  /// When the page navigates to this URL scheme, the screen closes and
  /// returns that URL instead (the eCourse2 token callback).
  final String? returnScheme;

  @override
  State<CampusWebScreen> createState() => _CampusWebScreenState();
}

class _CampusWebScreenState extends State<CampusWebScreen> {
  late final WebViewController _controller;
  late final CasAutofill _cas;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onNavigationRequest: (request) {
            final scheme = widget.returnScheme;
            if (scheme == null || !request.url.startsWith('$scheme:')) {
              return NavigationDecision.navigate;
            }
            // Ask about the password first, so closing pops this screen and
            // not the dialog.
            _cas.signedIn().then((_) {
              if (mounted) Navigator.of(context).pop(request.url);
            });
            return NavigationDecision.prevent;
          },
          onPageFinished: (url) => _cas.pageFinished(url),
        ),
      );
    // The channel must exist before the first page loads.
    _cas = CasAutofill(_controller, context);
    final form = widget.form;
    _controller.loadRequest(
      Uri.parse(widget.url),
      method: form == null ? LoadRequestMethod.get : LoadRequestMethod.post,
      headers: form == null
          ? const {}
          : const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: form == null
          ? null
          : Uint8List.fromList(utf8.encode(Uri(queryParameters: form).query)),
    );
  }

  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subBar(context, widget.title),
      body: Padding(
        // The floating nav bar covers the bottom of the shell's body.
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Stack(
          children: [
            CampusWebView(controller: _controller),
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
          ],
        ),
      ),
    );
  }
}
