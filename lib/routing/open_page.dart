import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens [path] over the page shown when it belongs to the tab shown; a page
/// of another tab opens in that tab instead. Pushed here, it would build that
/// tab's list-beside ShellRoute a second time, and the one navigator key the
/// two share moves over, leaving the other tab blank.
void openPage(BuildContext context, String path, {Object? extra}) {
  final router = GoRouter.of(context);
  final here = router.routerDelegate.currentConfiguration.uri.path;
  final routes = router.configuration.routes;
  if (tabOf(routes, path) == tabOf(routes, here)) {
    context.push(path, extra: extra);
  } else {
    context.go(path, extra: extra);
  }
}

/// The index of the shell branch whose top routes start [path], or null for
/// a path outside the tabs (the sign-in page).
int? tabOf(List<RouteBase> routes, String path) {
  final first = Uri.parse(path).pathSegments.firstOrNull;
  for (final route in routes) {
    if (route is! StatefulShellRoute) continue;
    for (final (i, branch) in route.branches.indexed) {
      if (_tops(branch.routes).any((p) => p == '/$first')) return i;
    }
  }
  return null;
}

/// A branch's top paths, looking through the ShellRoutes around them.
Iterable<String> _tops(List<RouteBase> routes) sync* {
  for (final r in routes) {
    if (r is GoRoute) yield r.path;
    if (r is ShellRoute) yield* _tops(r.routes);
  }
}
