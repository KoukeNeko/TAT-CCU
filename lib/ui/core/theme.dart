import 'package:flutter/material.dart';

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

/// The four functional blocks: lilac = now/selected, mint = next/schedule,
/// peach = due/attention, sun = unread.
@immutable
class Tones extends ThemeExtension<Tones> {
  const Tones({
    required this.lilac,
    required this.mint,
    required this.peach,
    required this.sun,
  });

  final Tone lilac, mint, peach, sun;

  List<Tone> get cycle => [lilac, mint, peach, sun];

  /// Stable color per course so a course keeps its color on every screen.
  Tone forCourse(int courseId) => cycle[courseId % cycle.length];

  /// Values are taken verbatim from design/round-02/screens.html: light
  /// containers are pastel, dark containers are deep tones of the same hues
  /// with the accent lifted, so badges stay the brightest thing on screen.
  factory Tones.of(Brightness b) => b == Brightness.light
      ? const Tones(
          lilac: Tone(Color(0xFFEADDFF), Color(0xFF21005D), Color(0xFF6750A4)),
          mint: Tone(Color(0xFFC4EED0), Color(0xFF0F2E1A), Color(0xFF2E7D4F)),
          peach: Tone(Color(0xFFFFDBCB), Color(0xFF2B1206), Color(0xFFB4532A)),
          sun: Tone(Color(0xFFFFE08A), Color(0xFF2A2100), Color(0xFF8A6D00)),
        )
      : const Tones(
          lilac: Tone(Color(0xFF4A3780), Color(0xFFEADDFF), Color(0xFFD0BCFF)),
          mint: Tone(Color(0xFF1D4A30), Color(0xFFC4EED0), Color(0xFF8DD7A4)),
          peach: Tone(Color(0xFF6A3720), Color(0xFFFFDBCB), Color(0xFFFFB596)),
          sun: Tone(Color(0xFF574400), Color(0xFFFFE08A), Color(0xFFEBC54A)),
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

ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final tones = Tones.of(brightness);
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: brightness,
    primary: tones.lilac.strong,
    onPrimary: tones.lilac.fill,
    primaryContainer: tones.lilac.fill,
    onPrimaryContainer: tones.lilac.ink,
    secondaryContainer: tones.lilac.fill,
    onSecondaryContainer: tones.lilac.ink,
    surface: Color(light ? 0xFFFFF8F4 : 0xFF17120F),
    onSurface: Color(light ? 0xFF22191A : 0xFFF1E3DD),
    onSurfaceVariant: Color(light ? 0xFF7A6766 : 0xFFB09A94),
    // nav bar / card / track surfaces from the mockup
    surfaceContainer: Color(light ? 0xFFFFF1EA : 0xFF221A17),
    surfaceContainerLow: Color(light ? 0xFFFFFFFF : 0xFF251D1A),
    surfaceContainerHigh: Color(light ? 0xFFF3E7E1 : 0xFF2C2320),
    outlineVariant: Color(light ? 0xFFF0E3DC : 0xFF3A2E2A),
  );
  final base = ThemeData(colorScheme: colors);
  final text = base.textTheme;
  return base.copyWith(
    extensions: [tones],
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
      toolbarHeight: 72,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: colors.onSurface,
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerHigh),
      hintStyle: WidgetStatePropertyAll(
        TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
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
