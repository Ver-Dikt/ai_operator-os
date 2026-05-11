import 'dart:ui';

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

    await tester.tap(find.text('image').first);
    await tester.pumpAndSettle();

    expect(find.text('Каталог'), findsWidgets);
    expect(find.text('Показано'), findsOneWidget);
  });
}
