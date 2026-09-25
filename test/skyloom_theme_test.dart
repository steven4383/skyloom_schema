import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() {
  test('builds a true-black dark theme by default', () {
    final theme = const SkyloomTheme().darkTheme;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.surface, Colors.black);
    expect(
      theme.extension<SkyloomThemeTokens>()?.visualStyle,
      SkyloomVisualStyle.standard,
    );
  });

  test('accepts custom colors and builds brutalism component themes', () {
    const seed = Color(0xFFFF4D00);
    final theme = const SkyloomTheme(
      seedColor: seed,
      visualStyle: SkyloomVisualStyle.brutalism,
    ).lightTheme;
    final tokens = theme.extension<SkyloomThemeTokens>();
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    final inputBorder =
        theme.inputDecorationTheme.border! as OutlineInputBorder;

    expect(
      theme.colorScheme.primary,
      ColorScheme.fromSeed(seedColor: seed).primary,
    );
    expect(tokens?.visualStyle, SkyloomVisualStyle.brutalism);
    expect(tokens?.surfaceRadius, 0);
    expect(cardShape.borderRadius, BorderRadius.zero);
    expect(cardShape.side.width, 2);
    expect(inputBorder.borderRadius, BorderRadius.zero);
    expect(inputBorder.borderSide.width, 2);
  });

  test('controller switches brightness, style, and seed color', () {
    final controller = SkyloomThemeController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.toggleBrightness(Brightness.light);
    controller.toggleVisualStyle();
    controller.setSeedColor(Colors.orange);

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.visualStyle, SkyloomVisualStyle.brutalism);
    expect(controller.seedColor, Colors.orange);
    expect(notifications, 3);
    controller.dispose();
  });
}
