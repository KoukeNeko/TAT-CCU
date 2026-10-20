import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../../l10n/l10n.dart';
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
  String title,
) async {
  if (context.read<EcourseAuthRepository>().isDemo) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.demoUnavailable)));
    return;
  }
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => CampusWebScreen(url: url, title: title),
    ),
  );
}

class CampusWebScreen extends StatefulWidget {
  const CampusWebScreen({
    super.key,
    required this.url,
    required this.title,
    this.returnScheme,
  });

  final String url, title;

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
    _controller.loadRequest(Uri.parse(widget.url));
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
            WebViewWidget(controller: _controller),
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
          ],
        ),
      ),
    );
  }
}
