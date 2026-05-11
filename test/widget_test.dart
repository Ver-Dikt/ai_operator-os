import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/ai_operator_app.dart';

void main() {
  testWidgets('startup routes open Phase 1 OS sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final entry in <String, String>{
      'commandCenter': 'AI Operator OS',
      'tools': 'Инструменты',
      'agents': 'Агенты',
      'workflows': 'Сценарии',
      'contentFactory': 'Контент-фабрика',
      'useCases': 'Кейсы',
      'projects': 'Проекты',
      'settings': 'Настройки',
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
    expect(find.text('Инструменты'), findsWidgets);

    await tester.tap(find.byIcon(Icons.smart_toy_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Агенты'), findsWidgets);

    await tester.tap(find.byIcon(Icons.schema_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Сценарии'), findsWidgets);

    await tester.tap(find.byIcon(Icons.tune_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsWidgets);
  });

  testWidgets('command center task routing uses route navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Собрать план'));
    await tester.tap(find.text('Собрать план'));
    await tester.pumpAndSettle();
    expect(find.text('Рекомендованный план'), findsOneWidget);
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
