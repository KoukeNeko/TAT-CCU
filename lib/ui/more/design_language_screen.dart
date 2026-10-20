import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../core/compose_screen.dart';
import '../core/glass.dart';
import '../core/glass_sheet.dart';
import '../core/floating_dock.dart';
import '../core/campus_session.dart';
import '../core/maintenance_capsule.dart';
import '../core/status_capsule.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Parts of the design language, each with its own detail page.
enum DesignPart { colors, corners, spacing, type, components, shapes }

String _partTitle(BuildContext context, DesignPart part) {
  final l10n = context.l10n;
  return switch (part) {
    DesignPart.colors => l10n.dlColors,
    DesignPart.corners => l10n.dlCorners,
    DesignPart.spacing => l10n.dlSpacing,
    DesignPart.type => l10n.dlType,
    DesignPart.components => l10n.dlComponents,
    DesignPart.shapes => l10n.dlShapes,
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
              padding: cardPadding,
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
                  // Light above dark.
                  child: Column(
                    children: [
                      for (final b in Brightness.values.reversed)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final t in Tones.of(b).cycle) ...[
                                Expanded(child: ColoredBox(color: t.fill)),
                                Expanded(child: ColoredBox(color: t.strong)),
                              ],
                            ],
                          ),
                        ),
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
                          padding: const EdgeInsets.only(right: Space.s),
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
                  [
                    rowGap,
                    sectionBelow,
                    pageMargin,
                    pageTop,
                  ].map((v) => v.round()).join('・'),
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
                      ],
                    ),
                  ),
                  'BarChip・StatusPill・StatusTile…',
                ),
              ],
            ),
            const SizedBox(height: rowGap),
            SizedBox(
              height: 150,
              child: tile(
                DesignPart.shapes,
                Row(
                  children: [
                    for (final shape in [spikyStar, clover, scallop])
                      Padding(
                        padding: const EdgeInsets.only(right: Space.m),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: ShapeDecoration(
                            color: tones.lilac.strong,
                            shape: shape,
                          ),
                        ),
                      ),
                    MorphingCookie(size: 44, color: tones.sun.strong),
                  ],
                ),
                'CookieBorder・MorphingCookie・CourseMark',
              ),
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
            DesignPart.colors => _bothModes(context, _colors),
            DesignPart.corners => _cornerList(context),
            DesignPart.spacing => _spacing(context),
            DesignPart.type => _type(context),
            DesignPart.components => _bothModes(context, _components),
            DesignPart.shapes => _bothModes(context, _shapes),
          },
        ),
      ),
    );
  }

  /// [sections] built for each theme: every section label once, then its
  /// content in light above dark.
  List<Widget> _bothModes(
    BuildContext context,
    List<Widget> Function(BuildContext, ThemeData) sections,
  ) {
    final font = Localizations.localeOf(context).languageCode == 'ja'
        ? fontJp
        : fontTw;
    final light = buildTheme(Brightness.light, fontFamily: font);
    final dark = buildTheme(Brightness.dark, fontFamily: font);
    final inLight = sections(context, light);
    final inDark = sections(context, dark);
    return [
      for (final (i, w) in inLight.indexed)
        w is SectionLabel
            ? w
            : Column(
                children: [
                  _ModePanel(
                    theme: light,
                    label: context.l10n.themeLight,
                    child: w,
                  ),
                  _ModePanel(
                    theme: dark,
                    label: context.l10n.themeDark,
                    child: inDark[i],
                  ),
                ],
              ),
    ];
  }

  List<Widget> _colors(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final tones = theme.extension<Tones>()!;
    final scheme = theme.colorScheme;
    final roles = [
      ('lilac', l10n.dlRoleNow, tones.lilac),
      ('mint', l10n.dlRoleNext, tones.mint),
      ('peach', l10n.dlRoleDue, tones.peach),
      ('sun', l10n.dlRoleUnread, tones.sun),
    ];
    Widget swatch(String name, Color bg, Color fg) => Expanded(
      child: Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.m, Space.m),
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
      Column(
        children: [
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
                            padding: const EdgeInsets.fromLTRB(
                              Space.m,
                              Space.m,
                              Space.m,
                              Space.m,
                            ),
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
        ],
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
              padding: const EdgeInsets.all(Space.s),
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
            padding: cardPadding,
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
              padding: cardPadding,
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
          padding: const EdgeInsets.symmetric(vertical: Space.s),
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

  List<Widget> _components(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final tones = theme.extension<Tones>()!;
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
      SectionLabel(
        'FloatingDock',
        action: TextButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const _DockGallery())),
          child: Text(l10n.viewAll),
        ),
      ),
      _Sample(
        child: DockButton(
          onPressed: () {},
          tone: tones.lilac,
          child: Text(l10n.signUp),
        ),
      ),
      const SectionLabel('GlassSurface'),
      _Sample(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: GlassSurface(
            radius: BorderRadius.circular(Corners.card),
            child: const SizedBox(height: 64),
          ),
        ),
      ),
      const SectionLabel('showGlassSheet・showGlassMenu'),
      Builder(
        builder: (context) => Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () => showGlassSheet<void>(
                context,
                title: l10n.addRecipient,
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in [l10n.kindCatalog, l10n.kindJournal])
                      ListTile(title: Text(t)),
                  ],
                ),
              ),
              child: const Text('Sheet'),
            ),
            Builder(
              builder: (anchor) => FilledButton.tonal(
                onPressed: () {
                  final box = anchor.findRenderObject()! as RenderBox;
                  showGlassMenu<int>(
                    anchor,
                    anchor: box.localToGlobal(Offset.zero) & box.size,
                    selected: 0,
                    items: [
                      for (final (i, t) in [
                        l10n.kindCatalog,
                        l10n.kindJournal,
                      ].indexed)
                        (
                          value: i,
                          title: t,
                          detail: null,
                          icon: null,
                          tone: null,
                        ),
                    ],
                  );
                },
                child: const Text('Menu'),
              ),
            ),
          ],
        ),
      ),
      const SectionLabel('ComposeBar'),
      ComposeBar(hint: l10n.commentHint, onTap: () {}, inline: true),
      const SectionLabel('TextField'),
      TextField(decoration: InputDecoration(hintText: l10n.searchPeople)),
      const SizedBox(height: rowGap),
      TextField(
        decoration: InputDecoration(
          labelText: l10n.signUpEmail,
          errorText: l10n.sendFailed,
        ),
      ),
      const SectionLabel('RoundBackButton・PressFeedback'),
      Row(
        children: [
          const RoundBackButton(),
          const SizedBox(width: Space.m),
          PressFeedback(
            child: FilledButton(onPressed: () {}, child: Text(l10n.renew)),
          ),
        ],
      ),
      const SectionLabel('EmptyState'),
      SizedBox(height: 260, child: EmptyState(l10n.noMail)),
      const SectionLabel('ToneBlock'),
      Row(
        children: [
          for (final (i, t) in tones.cycle.indexed) ...[
            if (i > 0) const SizedBox(width: rowGap),
            Expanded(
              child: ToneBlock(
                tone: t,
                radius: Corners.row,
                padding: const EdgeInsets.all(Space.m),
                child: const SizedBox(height: 40),
              ),
            ),
          ],
        ],
      ),
      SectionLabel('SectionLabel', detail: l10n.itemCount(3)),
      const SectionLabel('StatusTile'),
      Row(
        children: [
          Expanded(
            child: StatusTile(
              tone: tones.peach,
              icon: Icons.assignment_outlined,
              title: l10n.dueThisWeek,
              status: '3',
              onTap: () {},
            ),
          ),
          const SizedBox(width: rowGap),
          Expanded(
            child: StatusTile(
              tone: tones.sun,
              icon: Icons.notifications_none,
              title: l10n.unread,
              status: '2',
              onTap: () {},
            ),
          ),
        ],
      ),
      const SectionLabel('StatusCapsule'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const ReadingCapsule(),
          const MaintenanceCapsule(back: false),
          const MaintenanceCapsule(back: true),
        ],
      ),
      const SectionLabel('LoadingView'),
      ClipRRect(
        borderRadius: BorderRadius.circular(Corners.card),
        child: const SizedBox(height: 280, child: LoadingView()),
      ),
      const SectionLabel('UpdatedAt'),
      UpdatedAt(DateTime.now()),
    ];
  }

  List<Widget> _shapes(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final tones = theme.extension<Tones>()!;
    final scheme = theme.colorScheme;
    Widget named(String name, Widget art) => Column(
      children: [
        art,
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return [
      const SectionLabel('CookieBorder'),
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          for (final (name, shape) in [
            ('spikyStar', spikyStar),
            ('clover', clover),
            ('scallop', scallop),
            ('CookieBorder()', const CookieBorder()),
          ])
            named(
              name,
              Container(
                width: 64,
                height: 64,
                decoration: ShapeDecoration(
                  color: tones.lilac.strong,
                  shape: shape,
                ),
              ),
            ),
        ],
      ),
      const SectionLabel('MorphingCookie'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MorphingCookie(size: 96, color: tones.lilac.fill),
          const SizedBox(width: 16),
          MorphingCookie(size: 44, color: tones.sun.strong),
          const SizedBox(width: 16),
          MorphingCookie(size: 26, color: tones.mint.strong),
        ],
      ),
      const SectionLabel('CourseMark'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (var id = 0; id < 6; id++) CourseMark(courseId: id)],
      ),
      const SectionLabel('CookieBadge'),
      Row(
        children: [
          CookieBadge(
            value: '88',
            unit: l10n.unitMinutes,
            color: tones.lilac.strong,
            ink: tones.lilac.fill,
            shape: spikyStar,
          ),
          const SizedBox(width: 16),
          CookieBadge(
            value: '3',
            unit: l10n.unitDays,
            color: tones.peach.strong,
            ink: tones.peach.fill,
            size: 72,
            shape: scallop,
          ),
        ],
      ),
    ];
  }
}

/// [child] on [theme]'s own surface, under the theme's name.
class _ModePanel extends StatelessWidget {
  const _ModePanel({
    required this.theme,
    required this.label,
    required this.child,
  });

  final ThemeData theme;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: rowGap),
      child: Theme(
        data: theme,
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.card),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [child] on the page's own background, padded the way a page holds it.
class _Sample extends StatelessWidget {
  const _Sample({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.l),
    // The dock pads itself by the nav bar's inset; none here.
    child: MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: child,
    ),
  );
}

/// Every FloatingDock the app shows.
class _DockGallery extends StatelessWidget {
  const _DockGallery();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tones = context.tones;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, 'FloatingDock'),
      body: Builder(
        builder: (context) => ListView(
          padding: scrollPadding(context, top: 0),
          children: [
            for (final (title, dock) in [
              (
                l10n.replyToThread,
                ComposeBar(hint: l10n.replyToThread, onTap: () {}),
              ),
              (
                l10n.signUp,
                DockButton(
                  onPressed: () {},
                  tone: tones.lilac,
                  child: Text(l10n.signUp),
                ),
              ),
              (
                l10n.signUpWaitlist,
                DockButton(
                  onPressed: () {},
                  tone: tones.sun,
                  child: Text(l10n.signUpWaitlist),
                ),
              ),
              (
                l10n.cancelSignUp,
                DockButton(
                  onPressed: () {},
                  tone: tones.peach,
                  child: Text(l10n.cancelSignUp),
                ),
              ),
              (
                l10n.goSignUp,
                DockButton(
                  onPressed: () {},
                  tone: tones.peach,
                  child: Text('${l10n.goSignUp} ↗'),
                ),
              ),
              (
                l10n.eventFull,
                DockButton(onPressed: null, child: Text(l10n.eventFull)),
              ),
              (
                l10n.signUpClosed,
                DockButton(onPressed: null, child: Text(l10n.signUpClosed)),
              ),
              (
                l10n.absenceNew,
                DockButton(
                  onPressed: () {},
                  tone: tones.lilac,
                  child: Text(l10n.absenceNew),
                ),
              ),
              (
                l10n.submit,
                DockButton(
                  onPressed: () {},
                  tone: tones.lilac,
                  child: Text(l10n.submit),
                ),
              ),
              (
                l10n.drRequest,
                DockButton(
                  onPressed: () {},
                  tone: tones.lilac,
                  child: Text(l10n.drRequest),
                ),
              ),
              (
                l10n.ptAdd,
                DockButton(
                  onPressed: () {},
                  tone: tones.lilac,
                  child: Text(l10n.ptAdd),
                ),
              ),
              (
                l10n.ptSaveCount(2),
                DockButton(
                  onPressed: () {},
                  tone: tones.lilac,
                  child: Text(l10n.ptSaveCount(2)),
                ),
              ),
              (
                l10n.ptDeleteCount(2),
                DockButton(
                  onPressed: () {},
                  tone: tones.peach,
                  child: Text(l10n.ptDeleteCount(2)),
                ),
              ),
            ]) ...[SectionLabel(title), _Sample(child: dock)],
          ],
        ),
      ),
    );
  }
}
