import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/state/app_settings.dart';

void main() {
  test('settings and favorites are persisted locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettings(preferences: preferences);

    await settings.toggleFavorite('kling');
    await settings.toggleFavoriteAgent('director-agent');
    await settings.toggleFavoriteWorkflow('ai-tool-finder');
    await settings.toggleFavoritePrompt('tool-router');
    await settings.setCompactCards(true);
    await settings.setOperatorMode(OperatorMode.local);
    await settings.setOllamaBaseUrl('http://127.0.0.1:11434');
    await settings.setStartupDestination(AppDestination.tools);

    final restored = AppSettings(preferences: preferences);

    expect(restored.isFavorite('kling'), isTrue);
    expect(restored.isFavoriteAgent('director-agent'), isFalse);
    expect(restored.isFavoriteWorkflow('ai-tool-finder'), isTrue);
    expect(restored.isFavoritePrompt('tool-router'), isTrue);
    expect(restored.compactCards, isTrue);
    expect(restored.operatorMode, OperatorMode.local);
    expect(restored.ollamaBaseUrl, 'http://127.0.0.1:11434');
    expect(restored.startupDestination, AppDestination.tools);
  });
}
