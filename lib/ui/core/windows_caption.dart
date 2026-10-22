import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Height of the caption drawn in place of Windows' own title bar, as tall
/// as the system's caption buttons.
const windowsCaptionHeight = kWindowCaptionHeight;

/// Removes Windows' title bar, keeping the frame that resizes the window;
/// [WindowsCaption] draws the buttons instead. Call before runApp.
Future<void> hideWindowsTitleBar() async {
  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
}

/// Draws the minimize, maximize and close buttons over the top of [child],
/// on a strip that moves the window when dragged. The pages draw under it,
/// so their bars reach the top edge of the window.
class WindowsCaption extends StatelessWidget {
  const WindowsCaption({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: windowsCaptionHeight,
          child: WindowCaption(
            brightness: Theme.of(context).brightness,
            backgroundColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
