import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final entries = [
      (t.lilac, spikyStar, '成績', '/more/grades'),
      (t.peach, scallop, '校務系統', '/more/portal'),
      (t.sun, spikyStar, '帳號', '/more/account'),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: topBar('更多'),
      body: // Builder: the list must read insets from inside this Scaffold,
          // where the glass app bar's height is part of the padding.
          Builder(
            builder: (context) => GridView.count(
              padding: scrollPadding(context),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.98,
              children: [
                for (final (tone, shape, label, path) in entries)
                  ToneBlock(
                    tone: tone,
                    radius: 32,
                    onTap: () => context.go(path),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: ShapeDecoration(
                            color: tone.strong,
                            shape: shape,
                          ),
                        ),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}
