import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../../domain/models/course.dart';
import 'button_press.dart';

// Direction C "形狀卡片" (design/設計說明.md): Material 3 Expressive color
// blocks and rounded shapes, built on stock widgets because Flutter's
// material library has no Expressive components yet.

/// One functional color block: a container fill and the ink drawn on it.
class Tone {
  const Tone(this.fill, this.ink, this.strong);

  final Color fill;
  final Color ink;

  /// Saturated variant for badges and shapes on top of [fill].
  final Color strong;

  static Tone fromSeed(Color seed, Brightness brightness) {
    final s = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return Tone(s.primaryContainer, s.onPrimaryContainer, s.primary);
  }
}

/// Two color roles:
/// - four functional blocks — lilac = now/selected, mint = next/schedule,
///   peach = due/attention, sun = unread;
/// - ten soft identity colors for things that need to tell each other apart
///   (courses, portal groups), chroma 24 from HCT (design/round-08, P1).
@immutable
class Tones extends ThemeExtension<Tones> {
  const Tones({
    required this.lilac,
    required this.mint,
    required this.peach,
    required this.sun,
    required this.identity,
  });

  final Tone lilac, mint, peach, sun;
  final List<Tone> identity;

  /// Built around [seed] (主題: wallpaper colors, design A): lilac becomes
  /// the seed's own palette, the other blocks lean toward it so they sit
  /// together, and the identity colors stay so courses keep theirs.
  Tones seeded(Color seed, Brightness brightness) {
    final hct = Hct.fromInt(seed.toARGB32());
    // As Android's own palettes: at least chroma 48, so a grey wallpaper
    // still gives a color.
    final palette = TonalPalette.of(hct.hue, math.max(hct.chroma, 48));
    Color at(int tone) => Color(palette.get(tone));
    Color lean(Color c) =>
        Color(Blend.harmonize(c.toARGB32(), seed.toARGB32()));
    Tone near(Tone t) => Tone(lean(t.fill), lean(t.ink), lean(t.strong));
    return Tones(
      // The tones lilac's own fill, ink and strong sit at.
      lilac: brightness == Brightness.light
          ? Tone(at(90), at(10), at(40))
          : Tone(at(30), at(90), at(80)),
      mint: near(mint),
      peach: near(peach),
      sun: near(sun),
      identity: identity,
    );
  }

  List<Tone> get cycle => [lilac, mint, peach, sun];

  /// Stable color per course so a course keeps its color on every screen.
  Tone forCourse(int courseId) =>
      identity[courseColorSlot(courseId) % identity.length];

  factory Tones.of(Brightness b) => b == Brightness.light
      ? const Tones(
          lilac: Tone(Color(0xFFEADDFF), Color(0xFF21005D), Color(0xFF6750A4)),
          mint: Tone(Color(0xFFC4EED0), Color(0xFF0F2E1A), Color(0xFF2E7D4F)),
          peach: Tone(Color(0xFFFFDBCB), Color(0xFF2B1206), Color(0xFFB4532A)),
          sun: Tone(Color(0xFFFFE08A), Color(0xFF2A2100), Color(0xFF8A6D00)),
          identity: [
            Tone(Color(0xFFE9DDFF), Color(0xFF1F1635), Color(0xFF63597C)), // 紫
            Tone(Color(0xFFDAE2FF), Color(0xFF0E1A37), Color(0xFF525E7D)), // 靛
            Tone(Color(0xFFC8E6FF), Color(0xFF001E2E), Color(0xFF436278)), // 天藍
            Tone(Color(0xFFBBECEA), Color(0xFF00201F), Color(0xFF386665)), // 湖綠
            Tone(Color(0xFFC9EBC7), Color(0xFF04210B), Color(0xFF486549)), // 薄荷
            Tone(Color(0xFFE4E6AE), Color(0xFF1B1D00), Color(0xFF5E6135)), // 橄欖
            Tone(Color(0xFFFDDFA6), Color(0xFF261900), Color(0xFF715B2E)), // 金黃
            Tone(Color(0xFFFFDBC8), Color(0xFF311302), Color(0xFF7F553A)), // 蜜桃
            Tone(Color(0xFFFFDAD6), Color(0xFF33110E), Color(0xFF82524C)), // 珊瑚
            Tone(Color(0xFFFFD9E5), Color(0xFF30111F), Color(0xFF7C5263)), // 玫瑰
          ],
        )
      : const Tones(
          lilac: Tone(Color(0xFF4A3780), Color(0xFFEADDFF), Color(0xFFD0BCFF)),
          mint: Tone(Color(0xFF1D4A30), Color(0xFFC4EED0), Color(0xFF8DD7A4)),
          peach: Tone(Color(0xFF6A3720), Color(0xFFFFDBCB), Color(0xFFFFB596)),
          sun: Tone(Color(0xFF574400), Color(0xFFFFE08A), Color(0xFFEBC54A)),
          identity: [
            Tone(Color(0xFF4B4163), Color(0xFFE9DDFF), Color(0xFFCEC0E8)), // 紫
            Tone(Color(0xFF3B4665), Color(0xFFDAE2FF), Color(0xFFBAC6EA)), // 靛
            Tone(Color(0xFF2A4A5F), Color(0xFFC8E6FF), Color(0xFFAACBE4)), // 天藍
            Tone(Color(0xFF1E4E4D), Color(0xFFBBECEA), Color(0xFFA0CFCD)), // 湖綠
            Tone(Color(0xFF304D33), Color(0xFFC9EBC7), Color(0xFFAECFAD)), // 薄荷
            Tone(Color(0xFF464920), Color(0xFFE4E6AE), Color(0xFFC7CA94)), // 橄欖
            Tone(Color(0xFF574419), Color(0xFFFDDFA6), Color(0xFFE0C38C)), // 金黃
            Tone(Color(0xFF643D25), Color(0xFFFFDBC8), Color(0xFFF3BB9A)), // 蜜桃
            Tone(Color(0xFF673B36), Color(0xFFFFDAD6), Color(0xFFF5B7B0)), // 珊瑚
            Tone(Color(0xFF623B4B), Color(0xFFFFD9E5), Color(0xFFEEB8CB)), // 玫瑰
          ],
        );

  @override
  Tones copyWith() => this;

  @override
  Tones lerp(ThemeExtension<Tones>? other, double t) =>
      t < 0.5 || other is! Tones ? this : other;
}

extension TonesContext on BuildContext {
  Tones get tones => Theme.of(this).extension<Tones>()!;
}

/// LINE Seed, bundled under the SIL OFL (assets/fonts). Japanese uses the
/// JP cut so kanji take Japanese shapes; everything else uses the TW cut,
/// which also covers Latin.
/// Corner radii every surface picks from.
abstract final class Corners {
  /// Icon tiles and small marks.
  static const small = 12.0;

  /// Pieces inside a card: a QR frame, a strip in a hero, grid tiles.
  static const inset = 18.0;

  /// List rows and small cards.
  static const row = 22.0;

  /// Cards and hero blocks; also the Card theme.
  static const card = 28.0;
}

/// The steps every padding picks from.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

/// Inside every card and tone block.
const cardPadding = EdgeInsets.all(Space.l);

/// Gap between the rows of a list.
const rowGap = Space.s;

/// Side margin of every page.
const pageMargin = Space.l;

/// Width from which the window takes the desktop layout (a sidebar instead
/// of the nav bar) and a page puts its list beside its detail. Pages
/// measure the area they get, which [PaneSize] reports.
const wideLayout = 840.0;

/// Width from which the window trades the nav bar for an icon rail (iPad
/// in portrait); the full sidebar opens over the page from it.
const railLayout = 600.0;

/// Width from which a page puts its list beside its detail (訊息, 更多, a
/// course) and lays the week and the month out in full.
const splitLayout = 680.0;

/// Every desktop column beside the main one: the 訊息 and 更多 lists, and
/// the panels beside the week, the month and today's class.
const paneWidth = 360.0;

/// Widest a single column of content grows, so a page in a wide area does
/// not stretch its cards and lines across it.
const readableWidth = 720.0;

/// Space between the app bar and a page's first content.
const pageTop = Space.xl;

/// Space above and below a section label.
const sectionAbove = Space.xl, sectionBelow = Space.m;

const fontTw = 'LINESeedTW';
const fontJp = 'LINESeedJP';

/// An input marked only by a bar down its left edge.
class BarInputBorder extends InputBorder {
  const BarInputBorder({required this.color});

  final Color color;

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  BarInputBorder copyWith({BorderSide? borderSide}) =>
      BarInputBorder(color: borderSide?.color ?? color);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  BarInputBorder scale(double t) => this;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top + 6, 4, rect.height - 12),
      const Radius.circular(2),
    ),
    Paint()..color = color,
  );
}

/// The app's theme; with [seed], built around it (主題: wallpaper colors).
ThemeData buildTheme(
  Brightness brightness, {
  String fontFamily = fontTw,
  Color? seed,
}) {
  final light = brightness == Brightness.light;
  final tones = seed == null
      ? Tones.of(brightness)
      : Tones.of(brightness).seeded(seed, brightness);
  // Surfaces take a light tint of the seed.
  Color tint(int argb) =>
      Color(seed == null ? argb : Blend.harmonize(argb, seed.toARGB32()));
  final colors = ColorScheme.fromSeed(
    seedColor: seed ?? const Color(0xFF6750A4),
    brightness: brightness,
    primary: tones.lilac.strong,
    onPrimary: tones.lilac.fill,
    primaryContainer: tones.lilac.fill,
    onPrimaryContainer: tones.lilac.ink,
    secondaryContainer: tones.lilac.fill,
    onSecondaryContainer: tones.lilac.ink,
    surface: tint(light ? 0xFFFFF8F4 : 0xFF17120F),
    onSurface: tint(light ? 0xFF22191A : 0xFFF1E3DD),
    onSurfaceVariant: tint(light ? 0xFF7A6766 : 0xFFB09A94),
    // nav bar / card / track surfaces from the mockup
    surfaceContainer: tint(light ? 0xFFFFF1EA : 0xFF221A17),
    surfaceContainerLow: tint(light ? 0xFFFFFFFF : 0xFF251D1A),
    surfaceContainerHigh: tint(light ? 0xFFF3E7E1 : 0xFF2C2320),
    outlineVariant: tint(light ? 0xFFF0E3DC : 0xFF3A2E2A),
  );
  final base = ThemeData(
    colorScheme: colors,
    fontFamily: fontFamily,
    fontFamilyFallback: [fontFamily == fontTw ? fontJp : fontTw],
  );
  final text = base.textTheme;
  final buttonText = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: base.textTheme.bodyMedium?.fontFamilyFallback,
    fontWeight: FontWeight.w900,
    fontSize: 16,
  );
  return base.copyWith(
    extensions: [tones],
    // No ripple and no press highlight: the main controls sink with a
    // tick instead (PressFeedback).
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w900),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      bodyMedium: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 76,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: colors.onSurface,
      ),
    ),
    // Inputs (design/round-11 input-field-variants V3): no box, only a bar
    // down the left edge; lilac while typing, peach on an error.
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.fromLTRB(
        Space.l,
        Space.m,
        Space.xs,
        Space.m,
      ),
      hintStyle: TextStyle(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w900,
          color: states.contains(WidgetState.error)
              ? tones.peach.strong
              : states.contains(WidgetState.focused)
              ? tones.lilac.strong
              : colors.onSurfaceVariant,
        ),
      ),
      prefixIconColor: colors.onSurfaceVariant,
      suffixIconColor: colors.onSurfaceVariant,
      border: BarInputBorder(color: colors.outlineVariant),
      enabledBorder: BarInputBorder(color: colors.outlineVariant),
      focusedBorder: BarInputBorder(color: tones.lilac.strong),
      errorBorder: BarInputBorder(color: tones.peach.strong),
      focusedErrorBorder: BarInputBorder(color: tones.peach.strong),
      errorStyle: TextStyle(
        color: tones.peach.strong,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
      ),
    ),
    // Buttons (design/round-18 A): a lilac capsule with a heavy label; on
    // a press it draws in, deepens and ticks (button_press.dart). No
    // hovered overlay; see splashFactory.
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(64, 48),
            // The family too: a button's text style replaces the theme's, so
            // without it the label falls back to the platform font.
            textStyle: buttonText,
          ).copyWith(
            shape: pressShape,
            backgroundBuilder: pressHaptic,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? tones.lilac.fill.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
    ),
    // Only the label until pressed; then a soft lilac capsule behind it.
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            textStyle: buttonText,
            overlayColor: Colors.transparent,
          ).copyWith(
            shape: pressShape,
            backgroundBuilder: pressHaptic,
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? tones.lilac.fill.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(overlayColor: Colors.transparent)
          .copyWith(shape: pressShape, backgroundBuilder: pressHaptic),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(overlayColor: Colors.transparent),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Corners.card)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surfaceContainer,
      indicatorColor: colors.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

/// Height of the desktop UI's title bars, the macOS title bar's own.
const desktopBarHeight = 52.0;

/// [theme] for the pointer-first desktop UI (design/round-25): toolbar
/// height title bars with 15 px titles, and controls sized for a mouse.
ThemeData desktopTheme(ThemeData theme) => theme.copyWith(
  visualDensity: VisualDensity.compact,
  // Text fields type at the desktop UI's 13–14 px.
  textTheme: theme.textTheme.copyWith(
    bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
  ),
  // Ruled boxes and pointer-sized buttons in place of the phone's soft
  // cards and pills.
  cardTheme: theme.cardTheme.copyWith(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: _deskButton(theme, theme.filledButtonTheme.style),
  ),
  textButtonTheme: TextButtonThemeData(
    style: _deskButton(theme, theme.textButtonTheme.style),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: _deskButton(theme, theme.outlinedButtonTheme.style),
  ),
  // A boxed field, as on a desktop, in place of the phone's edge bar.
  inputDecorationTheme: theme.inputDecorationTheme.copyWith(
    isDense: true,
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Space.m,
      vertical: 10,
    ),
    border: _box(theme.colorScheme.outlineVariant),
    enabledBorder: _box(theme.colorScheme.outlineVariant),
    focusedBorder: _box(theme.colorScheme.primary),
    errorBorder: _box(theme.colorScheme.error),
    focusedErrorBorder: _box(theme.colorScheme.error),
  ),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  appBarTheme: theme.appBarTheme.copyWith(
    toolbarHeight: desktopBarHeight,
    titleSpacing: Space.l,
    titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  ),
);

OutlineInputBorder _box(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(7),
  borderSide: BorderSide(color: color),
);

/// [base] at a pointer's size: 32 px high, 13 px text in its own font.
ButtonStyle _deskButton(ThemeData theme, ButtonStyle? base) {
  final text = base?.textStyle?.resolve({}) ?? theme.textTheme.labelLarge;
  return ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    textStyle: WidgetStatePropertyAll(
      (text ?? const TextStyle()).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    ),
  ).merge(base);
}
