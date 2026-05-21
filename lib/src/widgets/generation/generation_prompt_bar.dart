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
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xE60B0F16),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 34,
            offset: Offset(0, 20),
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
          const SizedBox(height: 12),
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
              const SizedBox(width: 12),
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
                    const SizedBox(height: 6),
                    TextField(
                      controller: _prompt,
                      minLines: compact ? 3 : 2,
                      maxLines: compact ? 6 : 8,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
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
          const SizedBox(height: 10),
          Text(
            widget.selectedProviderType.description,
            style: const TextStyle(color: Color(0xFF8B97A8), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0x14FFFFFF)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              final controls = [
                SizedBox(
                  width: narrow ? double.infinity : 270,
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
                      const SizedBox(height: 10),
                    ],
                    _GenerateButton(onPressed: _submit),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Wrap(spacing: 8, runSpacing: 8, children: controls),
                  ),
                  const SizedBox(width: 12),
                  _GenerateButton(onPressed: _submit),
                ],
              );
            },
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 12),
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

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('Генерировать'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF22D3EE),
        foregroundColor: const Color(0xFF031014),
        fixedSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      spacing: 8,
      runSpacing: 8,
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF22D3EE) : const Color(0x0FFFFFFF),
            border: Border.all(
              color: selected
                  ? const Color(0xFF22D3EE)
                  : const Color(0x1FFFFFFF),
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
              fontWeight: FontWeight.w900,
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
        fixedSize: const Size.fromHeight(44),
        side: const BorderSide(color: Color(0x1FFFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      width: 132,
      height: 44,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF11161F),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(12),
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
                  fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x99070A0F),
        border: Border.all(color: const Color(0x14FFFFFF)),
        borderRadius: BorderRadius.circular(14),
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
