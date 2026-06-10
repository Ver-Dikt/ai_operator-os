import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/ai_operator_app.dart';

void expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception is FlutterError) {
    fail(exception.toStringDeep());
  }
  expect(exception, isNull);
}

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
      expectNoFlutterException(tester);
    }
  });

  testWidgets('mobile top navigation opens primary sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    final imageAction = find.widgetWithText(FilledButton, 'Image Studio');
    final videoAction = find.widgetWithText(OutlinedButton, 'Video Studio');
    final browserAction = find.widgetWithText(OutlinedButton, 'Browser Hub');

    await tester.tap(imageAction);
    await tester.pumpAndSettle();
    expectNoFlutterException(tester);

    await tester.tap(find.text('OpenGenerativeAI').last);
    await tester.pumpAndSettle();
    await tester.tap(videoAction);
    await tester.pumpAndSettle();
    expectNoFlutterException(tester);

    await tester.tap(find.text('OpenGenerativeAI').last);
    await tester.pumpAndSettle();
    await tester.tap(browserAction);
    await tester.pumpAndSettle();
    expectNoFlutterException(tester);

    await tester.tap(find.byIcon(Icons.tune_rounded).last);
    await tester.pumpAndSettle();
    expectNoFlutterException(tester);
  });

  testWidgets('command center hero actions route without layout errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const AiOperatorApp());
    await tester.pumpAndSettle();

    final imageAction = find.widgetWithText(FilledButton, 'Image Studio');
    await tester.ensureVisible(imageAction);
    await tester.tap(imageAction);
    await tester.pumpAndSettle();
    expectNoFlutterException(tester);
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
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const AiOperatorApp());
      await tester.pumpAndSettle();

      expect(find.byType(AiOperatorApp), findsOneWidget);
      expectNoFlutterException(tester);
    }
  });
}
