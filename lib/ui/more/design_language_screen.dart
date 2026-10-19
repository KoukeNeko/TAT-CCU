import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Parts of the design language, each with its own detail page.
enum DesignPart { colors, corners, spacing, type, components }

String _partTitle(BuildContext context, DesignPart part) {
  final l10n = context.l10n;
  return switch (part) {
    DesignPart.colors => l10n.dlColors,
    DesignPart.corners => l10n.dlCorners,
    DesignPart.spacing => l10n.dlSpacing,
    DesignPart.type => l10n.dlType,
    DesignPart.components => l10n.dlComponents,
  };
}

/// The type scale pages use. Shown here only; screens set their own sizes.
const _typeScale = [
  (34.0, FontWeight.w900),
  (22.0, FontWeight.w900),
  (17.0, FontWeight.w900),
  (15.0, FontWeight.w800),
  (13.0, FontWeight.w900),
  (12.0, FontWeight.w700),
];

const _corners = [
  ('small', Corners.small),
  ('inset', Corners.inset),
  ('row', Corners.row),
  ('card', Corners.card),
];

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Design L3 (design/round-11): a wall of tiles, one per part of the
/// design language, each opening its details. Every value is read from
/// the theme itself, so the page cannot drift from the app.
class DesignLanguageScreen extends StatelessWidget {
  const DesignLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    void open(DesignPart p) => context.push('/more/design/${p.name}');
    Widget tile(DesignPart part, Widget art, String caption, {int span = 1}) =>
        Material(
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => open(part),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _partTitle(context, part),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: art),
                  const SizedBox(height: 10),
                  Text(
                    caption,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, context.l10n.designLanguage),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            SizedBox(
              height: 150,
              child: tile(
                DesignPart.colors,
                ClipRRect(
                  borderRadius: BorderRadius.circular(Corners.small),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final t in tones.cycle) ...[
                        Expanded(child: ColoredBox(color: t.fill)),
                        Expanded(child: ColoredBox(color: t.strong)),
                      ],
                    ],
                  ),
                ),
                '${tones.cycle.length}・${tones.identity.length}',
              ),
            ),
            const SizedBox(height: rowGap),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: rowGap,
              crossAxisSpacing: rowGap,
              childAspectRatio: 0.95,
              children: [
                tile(
                  DesignPart.corners,
                  Stack(
                    children: [
                      for (final (i, (_, r)) in _corners.reversed.indexed)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            width: 76 - i * 15,
                            height: 76 - i * 15,
                            decoration: BoxDecoration(
                              color: tones.lilac.fill,
                              border: Border.all(
                                color: tones.lilac.strong,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(r),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _corners.map((c) => c.$2.round()).join('・'),
                ),
                tile(
                  DesignPart.spacing,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final v in [
                        rowGap,
                        sectionBelow,
                        pageMargin,
                        pageTop,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 14,
                            height: v * 2.6,
                            decoration: BoxDecoration(
                              color: tones.mint.fill,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                  [rowGap, pageMargin, pageTop].map((v) => v.round()).join('・'),
                ),
                tile(
                  DesignPart.type,
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Aa 字',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  'LINE Seed TW・JP',
                ),
                tile(
                  DesignPart.components,
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        BarChip(
                          label: context.l10n.kindCatalog,
                          selected: true,
                          onTap: () => open(DesignPart.components),
                        ),
                        StatusPill(
                          tone: tones.mint,
                          label: context.l10n.onShelf,
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: ShapeDecoration(
                            color: tones.lilac.strong,
                            shape: scallop,
                          ),
                        ),
                      ],
                    ),
                  ),
                  'BarChip・StatusPill・CookieBorder',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One part of the design language in detail (L1's sections).
class DesignPartScreen extends StatelessWidget {
  const DesignPartScreen({super.key, required this.part});

  final DesignPart part;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, _partTitle(context, part)),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: switch (part) {
            DesignPart.colors => _colors(context),
            DesignPart.corners => _cornerList(context),
            DesignPart.spacing => _spacing(context),
            DesignPart.type => _type(context),
            DesignPart.components => _components(context),
          },
        ),
      ),
    );
  }

  List<Widget> _colors(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    final scheme = Theme.of(context).colorScheme;
    final roles = [
      ('lilac', l10n.dlRoleNow, tones.lilac),
      ('mint', l10n.dlRoleNext, tones.mint),
      ('peach', l10n.dlRoleDue, tones.peach),
      ('sun', l10n.dlRoleUnread, tones.sun),
    ];
    Widget swatch(String name, Color bg, Color fg) => Expanded(
      child: Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _hex(bg),
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
    return [
      SectionLabel(l10n.dlFunctional, detail: 'fill・ink・strong'),
      for (final (name, role, t) in roles)
        Padding(
          padding: const EdgeInsets.only(bottom: rowGap),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Corners.row),
            child: ColoredBox(
              color: scheme.surfaceContainerLow,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Laid out like the swatches: name on top, role on the
                    // line of their color codes.
                    SizedBox(
                      width: 88,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    swatch('fill', t.fill, t.ink),
                    swatch('ink', t.ink, t.fill),
                    swatch('strong', t.strong, t.fill),
                  ],
                ),
              ),
            ),
          ),
        ),
      SectionLabel(l10n.dlIdentity),
      GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.2,
        children: [
          for (final t in tones.identity)
            Container(
              decoration: BoxDecoration(
                color: t.fill,
                borderRadius: BorderRadius.circular(Corners.small),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: t.strong,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _cornerList(BuildContext context) {
    final tone = context.tones.lilac;
    return [
      for (final (name, r) in _corners)
        Padding(
          padding: const EdgeInsets.only(bottom: rowGap),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tone.fill,
              borderRadius: BorderRadius.circular(r),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              '${r.round()}  Corners.$name',
              style: TextStyle(
                color: tone.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _spacing(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = context.tones.peach;
    return [
      for (final (name, v) in [
        ('pageMargin', pageMargin),
        ('pageTop', pageTop),
        ('sectionAbove', sectionAbove),
        ('sectionBelow', sectionBelow),
        ('rowGap', rowGap),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: rowGap),
          child: Material(
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.row),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: v * 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tone.fill,
                      border: Border.symmetric(
                        vertical: BorderSide(color: tone.strong, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${v.round()}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _type(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sample = context.l10n.designLanguage;
    return [
      for (final (size, weight) in _typeScale)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  sample,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: size, fontWeight: weight),
                ),
              ),
              Text(
                '${size.round()}・${weight.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _components(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    return [
      const SectionLabel('BarChip'),
      ChipRow(
        padding: EdgeInsets.zero,
        children: [
          BarChip(label: l10n.kindCatalog, selected: true, onTap: () {}),
          BarChip(label: l10n.kindJournal, selected: false, onTap: () {}),
          BarChip(
            label: l10n.filterType,
            selected: false,
            dropdown: true,
            onTap: () {},
          ),
        ],
      ),
      const SectionLabel('StatusPill'),
      Wrap(
        spacing: 6,
        children: [
          StatusPill(tone: tones.mint, label: l10n.onShelf),
          StatusPill(tone: tones.sun, label: l10n.checkedOut),
          StatusPill(tone: tones.peach, label: l10n.loansOverdue),
          StatusPill(tone: tones.lilac, label: l10n.online),
        ],
      ),
      const SectionLabel('Button'),
      Wrap(
        spacing: 8,
        children: [
          FilledButton(onPressed: () {}, child: Text(l10n.renew)),
          FilledButton.tonal(onPressed: () {}, child: Text(l10n.share)),
          TextButton(onPressed: () {}, child: Text(l10n.viewAll)),
        ],
      ),
      const SectionLabel('ToneBlock'),
      Row(
        children: [
          for (final (i, t) in tones.cycle.indexed) ...[
            if (i > 0) const SizedBox(width: rowGap),
            Expanded(
              child: ToneBlock(
                tone: t,
                radius: Corners.row,
                padding: const EdgeInsets.all(12),
                child: const SizedBox(height: 40),
              ),
            ),
          ],
        ],
      ),
      const SectionLabel('CookieBorder'),
      Row(
        children: [
          for (final shape in [spikyStar, clover, scallop])
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  color: tones.lilac.strong,
                  shape: shape,
                ),
              ),
            ),
        ],
      ),
    ];
  }
}
