import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:tat_ccu/ui/core/theme.dart';

double _hue(Color c) => Hct.fromInt(c.toARGB32()).hue;

/// Shortest way round the hue circle.
double _apart(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  const blue = Color(0xFF2F6DB5);

  for (final brightness in Brightness.values) {
    test('a wallpaper color replaces lilac, $brightness', () {
      final own = Tones.of(brightness);
      final seeded = own.seeded(blue, brightness);
      // Lilac takes the wallpaper's hue.
      expect(_apart(_hue(seeded.lilac.strong), _hue(blue)), lessThan(10));
      // The other blocks only lean toward it, so their meaning holds.
      for (final (a, b) in [
        (own.mint, seeded.mint),
        (own.peach, seeded.peach),
        (own.sun, seeded.sun),
      ]) {
        expect(_apart(_hue(a.strong), _hue(b.strong)), lessThanOrEqualTo(15.5));
      }
      // Courses keep their colors.
      expect(seeded.identity, own.identity);
    });
  }

  test('the theme takes the seed and keeps its light and dark', () {
    final theme = buildTheme(Brightness.dark, seed: blue);
    expect(theme.extension<Tones>()!.lilac.strong, theme.colorScheme.primary);
    expect(theme.brightness, Brightness.dark);
    expect(
      buildTheme(Brightness.dark).colorScheme.primary,
      Tones.of(Brightness.dark).lilac.strong,
    );
  });
}
