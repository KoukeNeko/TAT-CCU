import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/core/segment_switch.dart';
import 'package:tat_ccu/ui/core/theme.dart';

void main() {
  testWidgets('dragging the switch does not swipe the page behind it', (
    t,
  ) async {
    final pages = PageController();
    addTearDown(pages.dispose);
    var selected = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: PageView(
            controller: pages,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: StatefulBuilder(
                  builder: (context, setState) => SegmentSwitch(
                    labels: const ['收件匣', '寄件備份'],
                    selected: selected,
                    tone: context.tones.sun,
                    segment: 88,
                    onChanged: (i) => setState(() => selected = i),
                  ),
                ),
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
    final start =
        t.getTopLeft(find.byType(SegmentSwitch)) + const Offset(30, 20);
    // Leftward, as a swipe to the next page would go; then back past the
    // middle to the second side.
    final drag = await t.startGesture(start + const Offset(150, 0));
    for (var x = 150.0; x >= 0; x -= 10) {
      await drag.moveTo(start + Offset(x, 0));
      await t.pump();
      // Mid-drag is when a swiping page shows; released slowly it springs
      // back.
      expect(pages.page, 0);
    }
    await drag.moveTo(start + const Offset(120, 0));
    await drag.up();
    await t.pumpAndSettle();
    expect(pages.page, 0);
    expect(selected, 1);
  });

  Future<List<int>> pumpWide(
    WidgetTester t, {
    Set<int> disabled = const {},
  }) async {
    final picked = <int>[];
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 408,
              child: SegmentSwitch(
                labels: const ['跟隨系統', '繁中', 'English', '日本語'],
                selected: 0,
                disabled: disabled,
                onChanged: picked.add,
              ),
            ),
          ),
        ),
      ),
    );
    return picked;
  }

  // Shares 408 wide: four options of 100 after the track's padding.
  Offset at(WidgetTester t, int i) =>
      t.getTopLeft(find.byType(SegmentSwitch)) + Offset(4 + 100.0 * i + 50, 20);

  testWidgets('a drag across picks the option it ends on', (t) async {
    final picked = await pumpWide(t);
    final drag = await t.startGesture(at(t, 0));
    for (final i in [1, 2]) {
      await drag.moveTo(at(t, i));
      await t.pump();
    }
    await drag.up();
    expect(picked, [2]);
  });

  testWidgets('a disabled option cannot be picked', (t) async {
    final picked = await pumpWide(t, disabled: {3});
    await t.tapAt(at(t, 3));
    // Dragged onto, the capsule stays where it was.
    final drag = await t.startGesture(at(t, 2));
    await drag.moveTo(at(t, 3));
    await t.pump();
    await drag.up();
    expect(picked, [2]);
  });
}
