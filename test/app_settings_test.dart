import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_operator_os/src/state/app_settings.dart';

void main() {
  test('settings and favorites are persisted locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettings(preferences: preferences);

    await settings.toggleFavorite('kling');
    await settings.setCompactCards(true);
    await settings.setShowSensitiveTools(true);
    await settings.setStartupDestination(AppDestination.catalog);

    final restored = AppSettings(preferences: preferences);

    expect(restored.isFavorite('kling'), isTrue);
    expect(restored.compactCards, isTrue);
    expect(restored.showSensitiveTools, isTrue);
    expect(restored.startupDestination, AppDestination.catalog);
  });
}
