import 'package:flutter/material.dart';

import '../../models/generation/generation_provider.dart';
import '../../models/generation/generation_request.dart';
import 'provider_selector.dart';
import 'reference_picker.dart';

class GenerationPromptBar extends StatefulWidget {
  const GenerationPromptBar({
    super.key,
    required this.capability,
    required this.providers,
    required this.selectedProviderId,
    required this.onProviderChanged,
    required this.selectedProviderType,
    required this.availableProviderTypes,
    required this.onProviderTypeChanged,
    required this.references,
    required this.onAddReference,
    required this.onClearReferences,
    required this.onGenerate,
    this.onPromptChanged,
    this.initialPrompt = '',
    this.showDuration = false,
  });

  final GenerationCapability capability;
  final List<GenerationProvider> providers;
  final String selectedProviderId;
  final ValueChanged<String> onProviderChanged;
  final GenerationProviderType selectedProviderType;
  final Set<GenerationProviderType> availableProviderTypes;
  final ValueChanged<GenerationProviderType> onProviderTypeChanged;
  final List<String> references;
  final VoidCallback onAddReference;
  final VoidCallback onClearReferences;
  final ValueChanged<GenerationRequest> onGenerate;
  final ValueChanged<String>? onPromptChanged;
  final String initialPrompt;
  final bool showDuration;

  @override
  State<GenerationPromptBar> createState() => _GenerationPromptBarState();
}

class _GenerationPromptBarState extends State<GenerationPromptBar> {
  late final TextEditingController _prompt = TextEditingController(
    text: widget.initialPrompt,
  );
  String _aspectRatio = '16:9';
  String _quality = 'Balanced';
  int _duration = 5;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prompt.addListener(() => widget.onPromptChanged?.call(_prompt.text));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final selectedProvider = widget.providers.firstWhere(
      (provider) => provider.id == widget.selectedProviderId,
      orElse: () => widget.providers.first,
    );
    final actionLabel = _actionLabelFor(selectedProvider);
    return Container(
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: const Color(0xB80B0F16),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeSwitch(
            selected: widget.selectedProviderType,
            available: widget.availableProviderTypes,
            onChanged: widget.onProviderTypeChanged,
          ),
          const SizedBox(height: 10),
          _SelectedProviderPanel(provider: selectedProvider),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ReferencePicker(
                  references: widget.references,
                  onAddMock: widget.onAddReference,
                  onClear: widget.onClearReferences,
                  videoMode: widget.showDuration,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Промпт',
                      style: TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _prompt,
                      minLines: compact ? 3 : 2,
                      maxLines: compact ? 6 : 8,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: _hintFor(widget.capability),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.selectedProviderType.description,
            style: const TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0x14FFFFFF)),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final controls = [
                SizedBox(
                  width: narrow ? double.infinity : 255,
                  child: ProviderSelector(
                    providers: widget.providers,
                    selectedProviderId: widget.selectedProviderId,
                    onChanged: widget.onProviderChanged,
                  ),
                ),
                _MenuField(
                  icon: Icons.aspect_ratio_rounded,
                  value: _aspectRatio,
                  values: const ['16:9', '9:16', '1:1', '4:5', '21:9'],
                  onChanged: (value) => setState(() => _aspectRatio = value),
                ),
                _MenuField(
                  icon: Icons.high_quality_outlined,
                  value: _quality,
                  values: const ['Draft', 'Balanced', 'Pro'],
                  onChanged: (value) => setState(() => _quality = value),
                ),
                if (widget.showDuration)
                  _MenuField(
                    icon: Icons.timer_outlined,
                    value: '$_duration sec',
                    values: const ['5 sec', '10 sec', '30 sec'],
                    onChanged: (value) => setState(
                      () => _duration = int.parse(value.split(' ').first),
                    ),
                  ),
                _GhostButton(
                  icon: Icons.tune_rounded,
                  label: _showAdvanced ? 'Скрыть' : 'Параметры',
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                ),
              ];
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final control in controls) ...[
                      control,
                      const SizedBox(height: 8),
                    ],
                    _GenerateButton(label: actionLabel, onPressed: _submit),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Wrap(spacing: 8, runSpacing: 8, children: controls),
                  ),
                  const SizedBox(width: 10),
                  _GenerateButton(label: actionLabel, onPressed: _submit),
                ],
              );
            },
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 10),
            const _AdvancedStrip(),
          ],
        ],
      ),
    );
  }

  void _submit() {
    widget.onGenerate(
      GenerationRequest(
        prompt: _prompt.text.trim(),
        providerId: widget.selectedProviderId,
        capability: widget.capability,
        aspectRatio: _aspectRatio,
        quality: _quality,
        durationSeconds: widget.showDuration ? _duration : null,
        referencePaths: widget.references,
        metadata: const {'ui': 'studio-workspace'},
      ),
    );
  }

  String _actionLabelFor(GenerationProvider provider) {
    return switch (provider.type) {
      GenerationProviderType.browser ||
      GenerationProviderType.externalLink => 'Подготовить запуск',
      GenerationProviderType.local => 'Проверить local',
      GenerationProviderType.api =>
        provider.requiresApiKey ? 'Нужен API-ключ' : 'Генерировать',
    };
  }

  String _hintFor(GenerationCapability capability) {
    return switch (capability) {
      GenerationCapability.textToImage =>
        'Опиши изображение: объект, настроение, свет, объектив, композицию...',
      GenerationCapability.imageToImage =>
        'Опиши, как нужно изменить референс...',
      GenerationCapability.textToVideo =>
        'Опиши сцену, движение камеры, действие, свет и темп...',
      GenerationCapability.imageToVideo =>
        'Добавь стартовый кадр и опиши движение или эффект...',
      GenerationCapability.videoToVideo =>
        'Добавь видео и опиши обработку, рестайлинг или clean-up...',
    };
  }
}

class _SelectedProviderPanel extends StatelessWidget {
  const _SelectedProviderPanel({required this.provider});

  final GenerationProvider provider;

  @override
  Widget build(BuildContext context) {
    final url = provider.launchUrl ?? provider.localEndpoint;
    final isActionRoute =
        provider.type == GenerationProviderType.browser ||
        provider.type == GenerationProviderType.externalLink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x8C070A0F),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome_motion_rounded,
                color: Color(0xFF22D3EE),
                size: 18,
              ),
              Text(
                'Выбрано: ${provider.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _ProviderPill(provider.type.label),
              _ProviderPill(provider.statusLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            provider.description,
            style: const TextStyle(color: Color(0xFFA7B1C1), fontSize: 12),
          ),
          if (url != null) ...[
            const SizedBox(height: 6),
            SelectableText(
              url,
              style: const TextStyle(
                color: Color(0xFF7DD3FC),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (isActionRoute) ...[
            const SizedBox(height: 6),
            const Text(
              'Browser route: скопируйте production prompt, откройте сервис и сохраните результат вручную.',
              style: TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x22FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFDDE6F3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE7F7F4),
        foregroundColor: const Color(0xFF050609),
        fixedSize: const Size.fromHeight(38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.selected,
    required this.available,
    required this.onChanged,
  });

  final GenerationProviderType selected;
  final Set<GenerationProviderType> available;
  final ValueChanged<GenerationProviderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Режим',
          style: TextStyle(
            color: Color(0xFF8B97A8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        for (final mode in GenerationProviderType.values)
          _ModeChip(
            mode: mode,
            selected: selected == mode,
            enabled: available.contains(mode),
            onTap: () => onChanged(mode),
          ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final GenerationProviderType mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled ? mode.description : 'Нет провайдера для этого режима',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7F7F4) : const Color(0x0AFFFFFF),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE7F7F4)
                  : const Color(0x22FFFFFF),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            mode.workflowLabel,
            style: TextStyle(
              color: selected
                  ? Colors.black
                  : enabled
                  ? Colors.white70
                  : Colors.white24,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        fixedSize: const Size.fromHeight(38),
        side: const BorderSide(color: Color(0x24FFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MenuField extends StatelessWidget {
  const _MenuField({
    required this.icon,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final IconData icon;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 38,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: const Color(0x8011161F),
        border: Border.all(color: const Color(0x24FFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7D8798)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF0B0F16),
                iconEnabledColor: const Color(0xFF7D8798),
                style: const TextStyle(
                  color: Color(0xFFE8EEF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final item in values)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: (next) {
                  if (next != null) onChanged(next);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedStrip extends StatelessWidget {
  const _AdvancedStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x80070A0F),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _TinyChip('Seed: случайный'),
          _TinyChip('Сила стиля: 50%'),
          _TinyChip('Negative prompt готов'),
          _TinyChip('Batch: 1'),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
