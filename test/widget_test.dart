import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/ai_operator_app.dart';

void main() {
  testWidgets('catalog stays open when filters notify settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Каталог').last);
    await tester.pumpAndSettle();

    expect(find.text('Каталог'), findsWidgets);
    expect(find.text('Показано'), findsOneWidget);

    await tester.tap(find.text('image').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Каталог'), findsWidgets);
    expect(find.text('Показано'), findsOneWidget);
  });

  testWidgets('mobile navigation opens every main section', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Показано'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Пока пусто'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Стартовый экран'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Рабочие цепочки'), findsOneWidget);
  });
}
