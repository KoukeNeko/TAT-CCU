import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/core/pair_switch.dart';
import 'package:tat_ccu/ui/core/theme.dart';

void main() {
  testWidgets('dragging the switch does not swipe the page behind it', (
    t,
  ) async {
    final pages = PageController();
    addTearDown(pages.dispose);
    var second = false;
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
                  builder: (context, setState) => PairSwitch(
                    labels: ('收件匣', '寄件備份'),
                    second: second,
                    tone: context.tones.sun,
                    segment: 88,
                    onChanged: (v) => setState(() => second = v),
                  ),
                ),
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
    final start = t.getTopLeft(find.byType(PairSwitch)) + const Offset(30, 20);
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
    expect(second, isTrue);
  });
}
