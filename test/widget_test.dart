import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/ai_operator_app.dart';

void main() {
  testWidgets('startup routes open Phase 1 OS sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final entry in <String, String>{
      'commandCenter': 'Command Center',
      'tools': 'AI Tools',
      'agents': 'Agents',
      'workflows': 'Workflows',
      'contentFactory': 'Content Factory',
      'promptStudio': 'Prompt Studio',
      'modelRouter': 'Model Router',
      'freeCredits': 'Free Tools / Credits',
      'settings': 'Settings',
    }.entries) {
      SharedPreferences.setMockInitialValues({
        'startup_destination': entry.key,
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const AiOperatorApp());
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsWidgets);
    }
  });

  testWidgets('mobile bottom navigation opens primary sections', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('AI Tools'), findsWidgets);

    await tester.tap(find.byIcon(Icons.smart_toy_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Agents'), findsWidgets);

    await tester.tap(find.byIcon(Icons.factory_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Content Factory'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('command center task routing uses route navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Route task'));
    await tester.tap(find.text('Route task'));
    await tester.pumpAndSettle();
    expect(find.text('Model Router'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Command Center'), findsOneWidget);
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
