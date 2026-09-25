import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

import '../example/main.dart' as example;

void main() {
  testWidgets('feature guides navigate and expand on desktop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const example.SkyloomDocsApp());
    expect(find.bySemanticsLabel('Skyloom logo'), findsOneWidget);
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Feature guides'), findsOneWidget);
    await tester.tap(find.text('Responsive layout'));
    await tester.pumpAndSettle();
    expect(find.textContaining("'uiSchema':"), findsOneWidget);
  });

  testWidgets('feature guides navigate and expand on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const example.SkyloomDocsApp());
    expect(find.bySemanticsLabel('Skyloom logo'), findsOneWidget);
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Feature guides'), findsOneWidget);
    await tester.tap(find.text('Responsive layout'));
    await tester.pumpAndSettle();
    expect(find.textContaining("'uiSchema':"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appearance controls switch dark mode and visual style', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const example.SkyloomDocsApp());
    await tester.tap(find.byKey(const Key('theme-mode-toggle')));
    await tester.pumpAndSettle();

    var scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
    expect(Theme.of(scaffoldContext).scaffoldBackgroundColor, Colors.black);

    await tester.tap(find.byKey(const Key('visual-style-toggle')));
    await tester.pumpAndSettle();

    scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(scaffoldContext).extension<SkyloomThemeTokens>()?.visualStyle,
      SkyloomVisualStyle.brutalism,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('themes screen compares and applies both visual styles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const example.SkyloomDocsApp());
    await tester.tap(find.text('Themes'));
    await tester.pumpAndSettle();

    expect(find.text('Standard and brutalism themes'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Brutalism'), findsOneWidget);
    expect(find.text('Save preview'), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey('apply-brutalism')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(scaffoldContext).extension<SkyloomThemeTokens>()?.visualStyle,
      SkyloomVisualStyle.brutalism,
    );
    expect(tester.takeException(), isNull);
  });
}
