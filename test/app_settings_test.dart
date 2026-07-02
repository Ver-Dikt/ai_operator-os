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
    await settings.setLastTextSelection(
      providerId: 'openrouter-api',
      model: 'openai/gpt-4o-mini',
    );
    settings.setProviderHealth(
      providerId: 'openrouter',
      statusLabel: 'Готово',
      message: 'Готово',
      testedAt: DateTime(2026, 7, 2, 12),
    );

    final restored = AppSettings(preferences: preferences);

    expect(restored.isFavorite('kling'), isTrue);
    expect(restored.isFavoriteAgent('director-agent'), isFalse);
    expect(restored.isFavoriteWorkflow('ai-tool-finder'), isTrue);
    expect(restored.isFavoritePrompt('tool-router'), isTrue);
    expect(restored.compactCards, isTrue);
    expect(restored.operatorMode, OperatorMode.local);
    expect(restored.ollamaBaseUrl, 'http://127.0.0.1:11434');
    expect(restored.startupDestination, AppDestination.tools);
    expect(restored.lastTextProviderId, 'openrouter-api');
    expect(restored.lastTextModel, 'openai/gpt-4o-mini');
    expect(restored.providerHealth('openrouter'), isNull);
    expect(settings.providerHealth('openrouter')?.statusLabel, 'Готово');
  });
}
