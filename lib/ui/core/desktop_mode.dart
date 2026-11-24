import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether the pointer-first desktop UI is shown (design/round-25): on a
/// desktop, on an Android PC (Googlebook, ChromeOS), and on Windows unless
/// a convertible is held as a tablet, which keeps the touch UI.
final desktopMode = ValueNotifier(
  Platform.isMacOS || Platform.isLinux || Platform.isWindows,
);

/// MainActivity.kt, windows/runner/flutter_window.cpp and
/// linux/runner/my_application.cc.
const _channel = MethodChannel('tat_ccu/desktop');

/// Asks the platform once, then follows a Windows convertible between
/// laptop and tablet.
Future<void> watchDesktopMode() async {
  if (Platform.isWindows) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'tablet') desktopMode.value = call.arguments != true;
    });
    desktopMode.value = await _channel.invokeMethod<bool>('tablet') != true;
  } else if (Platform.isAndroid) {
    desktopMode.value = await _channel.invokeMethod<bool>('pc') ?? false;
  }
}

/// Paints the GTK title bar in the page's color, so it reads as part of the
/// window: [child] is shown as it is.
class LinuxTitleBar extends StatefulWidget {
  const LinuxTitleBar({super.key, required this.child});

  final Widget child;

  @override
  State<LinuxTitleBar> createState() => _LinuxTitleBarState();
}

class _LinuxTitleBarState extends State<LinuxTitleBar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheme = Theme.of(context).colorScheme;
    int rgb(Color c) => c.toARGB32() & 0xFFFFFF;
    _channel.invokeMethod<void>('titleBar', [
      rgb(scheme.surface),
      rgb(scheme.onSurfaceVariant),
      rgb(scheme.surfaceContainerHighest),
      rgb(scheme.error),
      rgb(scheme.onError),
      rgb(scheme.outlineVariant),
      scheme.brightness == Brightness.dark,
    ]);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Carries [desktopMode] down the tree, so pages rebuild when it changes.
class DesktopScope extends InheritedWidget {
  const DesktopScope({super.key, required this.desktop, required super.child});

  final bool desktop;

  @override
  bool updateShouldNotify(DesktopScope old) => old.desktop != desktop;
}

bool desktopUi(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<DesktopScope>()?.desktop ??
    false;

/// Marks a list column with a page beside it: its bar leaves the search
/// field to the page at the window's right edge.
class LeadingPane extends InheritedWidget {
  const LeadingPane({super.key, required super.child});

  @override
  bool updateShouldNotify(LeadingPane old) => false;
}

bool inLeadingPane(BuildContext context) =>
    context.getInheritedWidgetOfExactType<LeadingPane>() != null;

/// Marks a page beside a list: the toolbar's first bar, with the sidebar
/// toggle, is the list's.
class BesideList extends InheritedWidget {
  const BesideList({super.key, required super.child});

  @override
  bool updateShouldNotify(BesideList old) => false;
}

/// The desktop sidebar's toggle, at the start of the toolbar
/// (design/round-25); [inset] clears the window buttons while the sidebar
/// is hidden.
class SidebarToggle extends InheritedWidget {
  const SidebarToggle({
    super.key,
    required this.inset,
    required this.onToggle,
    required super.child,
  });

  final double inset;
  final VoidCallback onToggle;

  @override
  bool updateShouldNotify(SidebarToggle old) => old.inset != inset;
}

/// The toggle for the bar in [context], if it is the toolbar's first.
SidebarToggle? sidebarToggleOf(BuildContext context) {
  if (context.getInheritedWidgetOfExactType<BesideList>() != null) return null;
  return context.dependOnInheritedWidgetOfExactType<SidebarToggle>();
}
