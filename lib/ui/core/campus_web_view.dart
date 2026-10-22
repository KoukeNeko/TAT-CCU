import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A [WebViewWidget] that can be hidden on every platform.
///
/// Windows draws the WebView as a native window above everything Flutter
/// paints, so neither a cover, [Offstage] nor a dialog on top hides it.
/// There it is shrunk to nothing while [hidden], while its tab is in the
/// background, or while another route such as a dialog is above its own,
/// so what Flutter draws stays visible.
class CampusWebView extends StatelessWidget {
  const CampusWebView({
    super.key,
    required this.controller,
    this.hidden = false,
  });

  final WebViewController controller;
  final bool hidden;

  static final _floatsAboveFlutter = Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    final web = WebViewWidget(controller: controller);
    if (!_floatsAboveFlutter) return web;
    // A tab kept in the background disables tickers but keeps its route current.
    final shown =
        !hidden &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    final factor = shown ? 1.0 : 0.0;
    return FractionallySizedBox(
      alignment: AlignmentDirectional.topStart,
      widthFactor: factor,
      heightFactor: factor,
      child: web,
    );
  }
}
