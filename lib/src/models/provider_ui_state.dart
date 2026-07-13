import 'package:flutter/material.dart';

/// Единый пользовательский язык состояний провайдеров и маршрутов.
///
/// Технические ошибки и подробности остаются на экране настройки, а рабочие
/// экраны показывают только состояние и следующий понятный шаг.
enum ProviderUiState {
  ready,
  needsApiKey,
  needsSetup,
  browser,
  manual,
  localUnavailable,
  checking,
  experimental,
  researchOnly,
  comingSoon,
}

extension ProviderUiStatePresentation on ProviderUiState {
  String get label => switch (this) {
    ProviderUiState.ready => 'Готово',
    ProviderUiState.needsApiKey => 'Нужен API-ключ',
    ProviderUiState.needsSetup => 'Нужна настройка',
    ProviderUiState.browser => 'Через сайт',
    ProviderUiState.manual => 'Вручную',
    ProviderUiState.localUnavailable => 'Локально недоступно',
    ProviderUiState.checking => 'Проверяется',
    ProviderUiState.experimental => 'Эксперимент',
    ProviderUiState.researchOnly => 'Только исследование',
    ProviderUiState.comingSoon => 'Скоро',
  };

  Color get color => switch (this) {
    ProviderUiState.ready => const Color(0xFF6BE4C9),
    ProviderUiState.needsApiKey || ProviderUiState.needsSetup =>
      const Color(0xFFFFC46B),
    ProviderUiState.browser => const Color(0xFF67E8F9),
    ProviderUiState.manual => const Color(0xFFB8C2D0),
    ProviderUiState.localUnavailable => const Color(0xFFFFA68A),
    ProviderUiState.checking => const Color(0xFF8FB8FF),
    ProviderUiState.experimental => const Color(0xFFC4A7FF),
    ProviderUiState.researchOnly || ProviderUiState.comingSoon =>
      const Color(0xFF7D8796),
  };

  IconData get icon => switch (this) {
    ProviderUiState.ready => Icons.check_circle_outline_rounded,
    ProviderUiState.needsApiKey => Icons.key_rounded,
    ProviderUiState.needsSetup => Icons.tune_rounded,
    ProviderUiState.browser => Icons.open_in_new_rounded,
    ProviderUiState.manual => Icons.edit_note_rounded,
    ProviderUiState.localUnavailable => Icons.cloud_off_rounded,
    ProviderUiState.checking => Icons.sync_rounded,
    ProviderUiState.experimental => Icons.science_outlined,
    ProviderUiState.researchOnly => Icons.menu_book_outlined,
    ProviderUiState.comingSoon => Icons.schedule_rounded,
  };
}

ProviderUiState providerUiStateFromLabel(String label) {
  final normalized = label.trim().toLowerCase();
  if (normalized.contains('api') &&
      (normalized.contains('ключ') || normalized.contains('key'))) {
    return ProviderUiState.needsApiKey;
  }
  if (normalized.contains('провер') || normalized.contains('checking')) {
    return ProviderUiState.checking;
  }
  if (normalized.contains('локаль') &&
      (normalized.contains('недоступ') || normalized.contains('offline'))) {
    return ProviderUiState.localUnavailable;
  }
  if (normalized.contains('экспер') || normalized.contains('experimental')) {
    return ProviderUiState.experimental;
  }
  if (normalized.contains('исслед') || normalized.contains('research')) {
    return ProviderUiState.researchOnly;
  }
  if (normalized.contains('скоро') || normalized.contains('coming')) {
    return ProviderUiState.comingSoon;
  }
  if (normalized.contains('сайт') || normalized.contains('browser')) {
    return ProviderUiState.browser;
  }
  if (normalized.contains('вруч') || normalized.contains('manual')) {
    return ProviderUiState.manual;
  }
  if (normalized.contains('настрой') || normalized.contains('setup')) {
    return ProviderUiState.needsSetup;
  }
  return ProviderUiState.ready;
}
