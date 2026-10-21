import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Asks again for what a page shows when it may have gone stale: the app
/// coming back, the page's tab coming back on screen, and every
/// [refreshEvery] while it stays there. A page under another or a tab in
/// the background (tickers off) waits, and nothing is asked again within
/// [staleAfter] of the last time.
mixin AutoRefresh<W extends StatefulWidget> on State<W> {
  /// Asks again; [markAsked] when it starts.
  void refresh();

  Duration get staleAfter => const Duration(minutes: 1);

  /// Null asks again only on coming back, for pages that are costly to read
  /// (the school's sites, through a signed-in web view).
  Duration? get refreshEvery => const Duration(minutes: 5);

  var _asked = DateTime.now();
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  ValueListenable<TickerModeData>? _shown;

  void markAsked() => _asked = DateTime.now();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refreshIfStale);
    if (refreshEvery case final every?) {
      _timer = Timer.periodic(every, (_) => _refreshIfStale());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.getValuesNotifier(context);
    if (shown == _shown) return;
    _shown?.removeListener(_shownChanged);
    _shown = shown..addListener(_shownChanged);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _timer?.cancel();
    _shown?.removeListener(_shownChanged);
    super.dispose();
  }

  void _shownChanged() {
    if (_shown?.value.enabled ?? false) _refreshIfStale();
  }

  void _refreshIfStale() {
    if (!mounted || !(_shown?.value.enabled ?? true)) return;
    if (DateTime.now().difference(_asked) < staleAfter) return;
    markAsked();
    refresh();
  }
}
