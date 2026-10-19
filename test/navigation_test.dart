import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tat_ccu/ui/core/app_shell.dart';

void main() {
  // go_router 18 looks for material_ui's MaterialApp, misses Flutter's, and
  // falls back to pages without transitions or the iOS back swipe.
  testWidgets('iOS edge swipe goes back from a page inside a tab', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final router = GoRouter(
      initialLocation: '/a/b',
      routes: [
        StatefulShellRoute(
          builder: (_, _, shell) => Scaffold(body: shell),
          navigatorContainerBuilder: (_, shell, children) =>
              AnimatedBranches(index: shell.currentIndex, children: children),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/a',
                  builder: (_, _) => const Scaffold(body: Text('root')),
                  routes: [
                    GoRoute(
                      path: 'b',
                      builder: (_, _) => const Scaffold(body: Text('detail')),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/c', builder: (_, _) => const Text('c'))],
            ),
          ],
        ),
      ],
    );
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();

    final swipe = await t.startGesture(const Offset(5, 300));
    for (var i = 0; i < 20; i++) {
      await swipe.moveBy(const Offset(20, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await swipe.up();
    await t.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
    expect(find.text('detail'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('back from a page opened in another tab returns to the opener', (
    t,
  ) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute(
          builder: (_, _, shell) => Scaffold(body: shell),
          navigatorContainerBuilder: (_, shell, children) =>
              AnimatedBranches(index: shell.currentIndex, children: children),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/a',
                  builder: (_, _) => const Scaffold(body: Text('today')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/c',
                  builder: (_, _) => const Scaffold(body: Text('courses')),
                  routes: [
                    GoRoute(
                      path: 'd',
                      builder: (_, _) => const Scaffold(body: Text('detail')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/c/d');
    await t.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    router.pop();
    await t.pumpAndSettle();
    expect(find.text('today'), findsOneWidget);
    expect(router.state.uri.path, '/a');
  });
}
