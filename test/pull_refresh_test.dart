import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/core/pull_refresh.dart';
import 'package:tat_ccu/ui/core/theme.dart';

void main() {
  testWidgets('pulling a list inside a page view refreshes', (t) async {
    var refreshed = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: PullRefresh(
            onRefresh: () async => refreshed++,
            // As the Messages filters: one list per page.
            child: PageView(
              children: [
                for (var p = 0; p < 2; p++)
                  ListView(
                    children: [
                      for (var i = 0; i < 30; i++) ListTile(title: Text('$i')),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.fling(find.text('0'), const Offset(0, 400), 1000);
    await t.pumpAndSettle();
    expect(refreshed, 1);
  });
}
