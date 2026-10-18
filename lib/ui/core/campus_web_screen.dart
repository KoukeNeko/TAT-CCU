import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'widgets.dart';

/// Opens a campus system inside the app. Every campus page uses this one
/// kind of WebView: they share the default cookie store, so the portal and
/// CAS sign-in made in any of them carries to the rest, and to the iCCU
/// loader, while the app runs.
Future<void> openCampusPage(BuildContext context, String url, String title) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampusWebScreen(url: url, title: title),
      ),
    );

class CampusWebScreen extends StatefulWidget {
  const CampusWebScreen({super.key, required this.url, required this.title});

  final String url, title;

  @override
  State<CampusWebScreen> createState() => _CampusWebScreenState();
}

class _CampusWebScreenState extends State<CampusWebScreen> {
  late final _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(onProgress: (p) => setState(() => _progress = p)),
    )
    ..loadRequest(Uri.parse(widget.url));

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
