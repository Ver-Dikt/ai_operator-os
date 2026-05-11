import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/ai_operator_app.dart';

void main() {
  testWidgets('startup routes open Phase 1 OS sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final destination in <String>[
      'commandCenter',
      'tools',
      'agents',
      'workflows',
      'contentFactory',
      'useCases',
      'projects',
      'settings',
    ]) {
      SharedPreferences.setMockInitialValues({
        'startup_destination': destination,
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const AiOperatorApp());
      await tester.pumpAndSettle();
      expect(find.byType(AiOperatorApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mobile bottom navigation opens primary sections', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.smart_toy_outlined).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.schema_outlined).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.tune_rounded).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('command center task routing updates recommendation panel', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recommended-plan')), findsOneWidget);
  });

  testWidgets('main sections render on narrow and wide layouts', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in <Size>[
      const Size(320, 720),
      const Size(390, 900),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const AiOperatorApp());
      await tester.pumpAndSettle();

      expect(find.byType(AiOperatorApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
