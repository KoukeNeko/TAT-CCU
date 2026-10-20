import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/services/ecourse_web.dart';
import '../../l10n/l10n.dart';
import '../core/campus_web_screen.dart';
import '../core/theme.dart';

/// The attendance plugin's QR holds `attendance.php?qrpass=…&sessid=…`; only
/// that page on eCourse2 is opened, so a scanned code cannot send the
/// signed-in session anywhere else.
bool isAttendanceLink(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host == ecourseHost &&
    uri.path == '/mod/attendance/attendance.php' &&
    int.tryParse(uri.queryParameters['sessid'] ?? '') != null;

/// Scans the classroom's attendance QR, then shows eCourse2's own form in the
/// signed-in campus WebView, where the student checks it and submits.
Future<void> scanAttendance(BuildContext context) async {
  final url = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(builder: (_) => const AttendanceScanScreen()),
  );
  if (url != null && context.mounted) {
    await openCampusPage(context, url, context.l10n.takeAttendance);
  }
}

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  final _scanner = MobileScannerController(formats: [BarcodeFormat.qrCode]);

  /// The last code that was not an attendance link, so its notice shows once.
  String? _rejected;
  var _done = false;

  void _detected(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      final uri = Uri.tryParse(raw);
      if (uri != null && isAttendanceLink(uri)) {
        _done = true;
        Navigator.of(context).pop(raw);
        return;
      }
      if (raw != _rejected) {
        _rejected = raw;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.notAttendanceCode)),
          );
      }
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mint = context.tones.mint;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _detected,
            errorBuilder: (context, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.cameraUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: mint.strong, width: 5),
                  borderRadius: BorderRadius.circular(Corners.card),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _scanner,
                    builder: (context, state, _) => IconButton.filledTonal(
                      tooltip: context.l10n.flashlight,
                      isSelected: state.torchState == TorchState.on,
                      onPressed: state.torchState == TorchState.unavailable
                          ? null
                          : _scanner.toggleTorch,
                      icon: const Icon(Icons.flashlight_off),
                      selectedIcon: const Icon(Icons.flashlight_on),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
