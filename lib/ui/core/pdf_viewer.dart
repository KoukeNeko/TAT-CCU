import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import 'widgets.dart';

const _pdfPreview = MethodChannel('tatccu/pdf_preview');

// pdfium finds no CJK font by itself; Android keeps them here. It can be
// pointed at fonts only once; top-level, so prepared on first use.
final _androidFonts = PdfFontManager(resolvers: const [])
    .prepare(fontPaths: const ['/system/fonts']);

/// Shows a saved PDF the way each system does. The school's PDFs leave their
/// CJK fonts out, which the system's own viewers fill in.
Future<void> showPdfFile(BuildContext context, File file, String title) async {
  if (Platform.isIOS) {
    // Quick Look, with its own share button.
    return _pdfPreview.invokeMethod('show', {
      'path': file.path,
      'title': title,
    });
  }
  // Preview on macOS, the default viewer on Windows.
  if (!Platform.isAndroid) {
    await launchUrl(Uri.file(file.path));
    return;
  }
  await _androidFonts;
  if (!context.mounted) return;
  final l10n = context.l10n;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: subBar(
          context,
          title,
          action: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return IconButton(
                tooltip: l10n.share,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHigh,
                  fixedSize: const Size(40, 40),
                ),
                icon: Icon(
                  Icons.share,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path, mimeType: 'application/pdf')],
                  ),
                ),
              );
            },
          ),
        ),
        body: PdfViewer.file(file.path),
      ),
    ),
  );
}
