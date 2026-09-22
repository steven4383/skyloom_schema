import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/main.dart' as example;

void main() {
  testWidgets('feature guides navigate and expand on desktop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const example.SkyloomDocsApp());
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
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();

    expect(find.text('Feature guides'), findsOneWidget);
    await tester.tap(find.text('Responsive layout'));
    await tester.pumpAndSettle();
    expect(find.textContaining("'uiSchema':"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
