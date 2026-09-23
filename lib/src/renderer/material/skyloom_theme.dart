import 'package:flutter/material.dart';

/// Visual treatments supplied by Skyloom's optional application themes.
enum SkyloomVisualStyle {
  /// A quiet, rounded Material 3 interface.
  standard,

  /// A high-contrast interface with square corners and heavy outlines.
  brutalism,
}

/// Theme tokens read by Skyloom's generated Material surfaces.
@immutable
final class SkyloomThemeTokens extends ThemeExtension<SkyloomThemeTokens> {
  const SkyloomThemeTokens({
    required this.visualStyle,
    required this.surfaceRadius,
    required this.fieldRadius,
    required this.borderWidth,
  });

  /// Default tokens used when no [SkyloomTheme] is installed.
  static const standard = SkyloomThemeTokens(
    visualStyle: SkyloomVisualStyle.standard,
    surfaceRadius: 16,
    fieldRadius: 12,
    borderWidth: 0,
  );

  /// Tokens used by the built-in brutalism theme.
  static const brutalism = SkyloomThemeTokens(
    visualStyle: SkyloomVisualStyle.brutalism,
    surfaceRadius: 0,
    fieldRadius: 0,
    borderWidth: 2,
  );

  /// Resolves Skyloom tokens from the nearest Material [Theme].
  static SkyloomThemeTokens of(BuildContext context) =>
      Theme.of(context).extension<SkyloomThemeTokens>() ?? standard;

  /// Selected visual treatment.
  final SkyloomVisualStyle visualStyle;

  /// Corner radius for sections, nested objects, and repeatable items.
  final double surfaceRadius;

  /// Corner radius for inputs and controls.
  final double fieldRadius;

  /// Width of generated-surface outlines.
  final double borderWidth;

  /// Whether the active treatment is [SkyloomVisualStyle.brutalism].
  bool get isBrutalism => visualStyle == SkyloomVisualStyle.brutalism;

  /// Creates the border used by generated nested surfaces.
  Border? surfaceBorder(ColorScheme colors) => borderWidth == 0
      ? null
      : Border.all(
          color: colors.brightness == Brightness.dark
              ? colors.onSurface
              : Colors.black,
          width: borderWidth,
        );

  @override
  SkyloomThemeTokens copyWith({
    SkyloomVisualStyle? visualStyle,
    double? surfaceRadius,
    double? fieldRadius,
    double? borderWidth,
  }) => SkyloomThemeTokens(
    visualStyle: visualStyle ?? this.visualStyle,
    surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    fieldRadius: fieldRadius ?? this.fieldRadius,
    borderWidth: borderWidth ?? this.borderWidth,
  );

  @override
  SkyloomThemeTokens lerp(
    covariant SkyloomThemeTokens? other,
    double t,
  ) {
    if (other == null) return this;
    return SkyloomThemeTokens(
      visualStyle: t < 0.5 ? visualStyle : other.visualStyle,
      surfaceRadius: _lerp(surfaceRadius, other.surfaceRadius, t),
      fieldRadius: _lerp(fieldRadius, other.fieldRadius, t),
      borderWidth: _lerp(borderWidth, other.borderWidth, t),
    );
  }

  static double _lerp(double start, double end, double t) =>
      start + (end - start) * t;
}

/// Builds coordinated light and dark Material themes for a Skyloom app.
///
/// This class is optional: generated forms continue to follow any host
/// application's [ThemeData]. Use it when an application wants Skyloom's
/// ready-made standard or brutalism visual treatment.
@immutable
final class SkyloomTheme {
  const SkyloomTheme({
    this.seedColor = const Color(0xFF276B5D),
    this.visualStyle = SkyloomVisualStyle.standard,
    this.pureBlackDark = true,
    this.lightColorScheme,
    this.darkColorScheme,
  });

  /// Seed used to create color schemes when explicit schemes are not supplied.
  final Color seedColor;

  /// Shape, border, and elevation treatment applied across the application.
  final SkyloomVisualStyle visualStyle;

  /// Whether the generated dark theme uses black as its base surface.
  final bool pureBlackDark;

  /// Optional complete light color override.
  final ColorScheme? lightColorScheme;

  /// Optional complete dark color override.
  final ColorScheme? darkColorScheme;

  /// Material theme for light mode.
  ThemeData get lightTheme => _build(Brightness.light, lightColorScheme);

  /// Material theme for dark mode.
  ThemeData get darkTheme => _build(Brightness.dark, darkColorScheme);

  ThemeData _build(Brightness brightness, ColorScheme? override) {
    final dark = brightness == Brightness.dark;
    var colors =
        override ??
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    if (dark && pureBlackDark && override == null) {
      colors = colors.copyWith(
        surface: Colors.black,
        surfaceDim: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF050505),
        surfaceContainer: const Color(0xFF0A0A0A),
        surfaceContainerHigh: const Color(0xFF111111),
        surfaceContainerHighest: const Color(0xFF181818),
      );
    } else if (!dark && override == null) {
      colors = colors.copyWith(surface: const Color(0xFFF6F8F7));
    }

    final brutalism = visualStyle == SkyloomVisualStyle.brutalism;
    final tokens = brutalism
        ? SkyloomThemeTokens.brutalism
        : SkyloomThemeTokens.standard;
    final ink = dark ? colors.onSurface : Colors.black;
    final outlineWidth = brutalism ? 2.0 : 1.0;
    final radius = brutalism ? 0.0 : 12.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(brutalism ? 0 : 20),
      side: BorderSide(
        color: brutalism ? ink : colors.outlineVariant,
        width: outlineWidth,
      ),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: brutalism ? ink : colors.outlineVariant,
        width: outlineWidth,
      ),
    );
    final focusedInputBorder = inputBorder.copyWith(
      borderSide: BorderSide(
        color: brutalism ? colors.primary : colors.primary,
        width: 2,
      ),
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(brutalism ? 0 : 12),
    );
    final controlSide = brutalism
        ? BorderSide(color: ink, width: 2)
        : BorderSide.none;

    var theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      cardTheme: CardThemeData(
        elevation: brutalism ? 6 : 0,
        shadowColor: brutalism ? ink : Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: colors.surfaceContainerLowest,
        shape: shape,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: brutalism ? 0 : 1,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: brutalism
            ? Border(bottom: BorderSide(color: ink, width: 2))
            : null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusedInputBorder,
      ),
      dividerTheme: DividerThemeData(
        color: brutalism ? ink : colors.outlineVariant,
        thickness: brutalism ? 2 : 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStatePropertyAll(controlSide),
          elevation: WidgetStatePropertyAll(brutalism ? 4 : 0),
          shadowColor: WidgetStatePropertyAll(ink),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          side: WidgetStatePropertyAll(
            BorderSide(color: ink, width: brutalism ? 2 : 1),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: controlShape,
        side: BorderSide(
          color: brutalism ? ink : colors.outlineVariant,
          width: outlineWidth,
        ),
        elevation: brutalism ? 2 : 0,
        pressElevation: brutalism ? 0 : null,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    if (brutalism) {
      theme = theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          headlineSmall: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          titleLarge: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          titleMedium: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          labelLarge: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return theme;
  }
}

/// Controls application brightness and Skyloom visual style at runtime.
final class SkyloomThemeController extends ChangeNotifier {
  SkyloomThemeController({
    ThemeMode themeMode = ThemeMode.system,
    SkyloomVisualStyle visualStyle = SkyloomVisualStyle.standard,
    Color seedColor = const Color(0xFF276B5D),
    bool pureBlackDark = true,
  }) : _themeMode = themeMode,
       _visualStyle = visualStyle,
       _seedColor = seedColor,
       _pureBlackDark = pureBlackDark;

  ThemeMode _themeMode;
  SkyloomVisualStyle _visualStyle;
  Color _seedColor;
  bool _pureBlackDark;

  /// Current Material brightness preference.
  ThemeMode get themeMode => _themeMode;

  /// Current standard or brutalism treatment.
  SkyloomVisualStyle get visualStyle => _visualStyle;

  /// Current application color seed.
  Color get seedColor => _seedColor;

  /// Whether the dark palette starts from true black.
  bool get pureBlackDark => _pureBlackDark;

  /// Theme configuration represented by the controller's current values.
  SkyloomTheme get theme => SkyloomTheme(
    seedColor: seedColor,
    visualStyle: visualStyle,
    pureBlackDark: pureBlackDark,
  );

  /// Selects light, dark, or platform-controlled brightness.
  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  /// Switches between light and dark using the currently rendered brightness.
  void toggleBrightness(Brightness currentBrightness) => setThemeMode(
    currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );

  /// Selects the standard or brutalism visual treatment.
  void setVisualStyle(SkyloomVisualStyle value) {
    if (_visualStyle == value) return;
    _visualStyle = value;
    notifyListeners();
  }

  /// Switches between the standard and brutalism treatments.
  void toggleVisualStyle() => setVisualStyle(
    visualStyle == SkyloomVisualStyle.standard
        ? SkyloomVisualStyle.brutalism
        : SkyloomVisualStyle.standard,
  );

  /// Rebuilds generated themes with a new seed color.
  void setSeedColor(Color value) {
    if (_seedColor == value) return;
    _seedColor = value;
    notifyListeners();
  }

  /// Enables or disables the true-black dark background.
  void setPureBlackDark(bool value) {
    if (_pureBlackDark == value) return;
    _pureBlackDark = value;
    notifyListeners();
  }
}
